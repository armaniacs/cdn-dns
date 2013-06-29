#!/usr/bin/env ruby

require 'socket'
require 'syslog'
require 'timeout'
require 'net/http'
require 'uri'
require 'resolv'
require 'find'
require 'time'
require 'drb/drb'

class StoreSurrogateLocal
  def initialize
    @ss = Hash.new
  end

  def dstatus(host, code)
    if @ss[host] && @ss[host][2]
      failCount = @ss[host][2]
    else
      failCount = 0
    end
    if code >= 400
      failCount += 1
    elsif code >= 200 && code < 300
      failCount = 0
    end
    @ss[host] = [code.to_i, Time.now, failCount]
  end

  def dcode(host)
    return @ss[host]
  end
end


class CheckSurrogate
  attr :lines

  def initialize
    @lines = ''
    @slog = Syslog.open(__FILE__,   
                        Syslog::Constants::LOG_PID |
                        Syslog::Constants::LOG_CONS,
                        Syslog::Constants::LOG_DAEMON)
    @last_modified = nil

    begin
      @keepd = DRbObject.new_with_uri('druby://localhost:38100') 
      @keepd.dstatus("127.0.0.2", 100)
    rescue 
      @slog.info("Use StoreSurrogateLocal")
      @keepd = StoreSurrogateLocal.new
      @keepd.dstatus("127.0.0.2", 100)
    end

  end

  def logclose
    @slog.close
  end

  def checkhttp(host, tracefile, first_surrogate=nil, port=80)
    begin
      keep = @keepd.dcode(host)
      if keep && keep[0] >= 500
        return nil
      elsif keep && keep[0] >= 400 && keep[1] + 10800 > Time.now
        return nil
      end

      h = Net::HTTP.new(host, port)
      h.open_timeout = 8 
      h.read_timeout = 8
      case response = h.head("/debian/project/trace/#{tracefile}", {"User-Agent" => "Debian-cdn-mirror-ping/1.1"})
      when Net::HTTPSuccess
        if first_surrogate
          @last_modified = Time.parse(response['last-modified'])
          @slog.info("#{host} return #{response.code} #{@last_modified} set")
          @keepd.dstatus(host, 200)
          return true
        elsif @last_modified && @last_modified == Time.parse(response['last-modified'])
          @slog.info("#{host} return #{response.code} #{@last_modified} equal")
          @keepd.dstatus(host, 200)
          return true
        elsif @last_modified && @last_modified != Time.parse(response['last-modified'])
          @slog.info("#{host} return #{response.code} #{response['last-modified']} different timestamp. Ignore this host.")
          @keepd.dstatus(host, 180)
          return nil
        else
          @slog.info("#{host} return #{response.code} (please set $first_surrogate")
          @keepd.dstatus(host, 200)
          return true
        end
      else
        @slog.info("#{host} return #{response.code}")
        @keepd.dstatus(host, response.code)
        return nil
      end
    rescue Timeout::Error
      @slog.info("#{host} timeout (#{$!})")
      return nil
    rescue Errno::ECONNREFUSED
      @slog.info("#{host} refused open (#{$!})")
      @keepd.dstatus(host, 500)
      return nil
    rescue
      @slog.info("#{host} some error (#{$!})")
      @keepd.dstatus(host, 500)
      return nil
    end
  end

  def make_surrogate_line(listfile)
    domain = listfile.gsub(/\.\/lists_/, '')
    domain.gsub!(/\.\/country\/[A-Z]+_/, '')
    domain.gsub!(/\.\/continent\/[A-Z]+_/, '')
    domain.gsub!(/_/, '.')

    surrogates = ''
    @last_modified = nil
    $surrogates = ''
    $tracefile = ''
    $first_surrogate = nil
    require listfile

    if $tracefile && $first_surrogate
      checkhttp($first_surrogate, $tracefile, true)
    end

    surrogates = $surrogates

    s_active = Hash.new
    surrogates.each do |t_ip, t_value|
      if checkhttp(t_ip, $tracefile)
        s_active[t_ip.gsub('.',',')] = t_value
      else
      end
    end

    @lines += "\t\"#{domain}\" => [\n"
    s_active.each do |k,v|
      @lines += "\t\t" + '[[' + k + '], ' + v + '],' + "\n"
    end
    @lines += "\t],\n"

  end
end ## end CheckSurrogate

domains = Array.new
$addr_db = Hash.new
begin
  Dir.mkdir(".addrs")
rescue
end

default_listfiles = Array.new
Find.find(File.dirname(__FILE__)) do |f|
  if f =~ /^\.\/lists_([\w_]+)\.rb$/
    cl = $1
    default_listfiles.push f.gsub(/\.rb$/,'')
  end
end

default_cs = CheckSurrogate.new

default_listfiles.each do |f|
  default_cs.make_surrogate_line(f)
end

foo = File.open(".addrs/default", 'w')
foo.puts "##" + Time.now.to_s + "\n\n"
foo.puts '$tmp_db = {
  "default" => {
    "ns.cdn.araki.net" => [
      [[210,157,158,38], 0],
    ],
    "localhost" => [
      [[127,0,0,1], 0],
    ],
'
foo.puts default_cs.lines
foo.puts '
  },
}'
foo.close
default_cs.logclose

###

listfiles = Array.new
countries = Array.new
Find.find(File.dirname(__FILE__) + '/country') do |f|
  if f =~ /^\.\/country\/([A-Z]+)_[\w_]+\.rb$/
    countries.push $1
  end
end
countries.uniq!
countries.each do |country|
  cs = CheckSurrogate.new
  Find.find(File.dirname(__FILE__) + '/country') do |f|
    if f =~ /^\.\/country\/#{country}_[\w_]+\.rb$/
      f.gsub!(/\.rb$/,'')
      cs.make_surrogate_line(f)
    end
  end
  foo = File.open(".addrs/#{country}", 'w')
  foo.puts "##" + Time.now.to_s + "\n\n"
  foo.puts "$tmp_db = {
  \"#{country}\" => {
"
  foo.puts cs.lines
  foo.puts '
  },
}'
  foo.close
  cs.logclose
end

###

listfiles = Array.new
continents = Array.new
Find.find(File.dirname(__FILE__) + '/continent') do |f|
  if f =~ /^\.\/continent\/([A-Z]+)_[\w_]+\.rb$/
    continents.push $1
  end
end
continents.uniq!
continents.each do |continent|
  cs = CheckSurrogate.new
  Find.find(File.dirname(__FILE__) + '/continent') do |f|
    if f =~ /^\.\/continent\/#{continent}_[\w_]+\.rb$/
      f.gsub!(/\.rb$/,'')
      cs.make_surrogate_line(f)
    end
  end
  foo = File.open(".addrs/#{continent}", 'w')
  foo.puts "##" + Time.now.to_s + "\n\n"
  foo.puts "$tmp_db = {
  \"#{continent}\" => {
"
  foo.puts cs.lines
  foo.puts '
  },
}'
  foo.close
  cs.logclose
end

###

Find.find(File.dirname(__FILE__) + '/.addrs') do |f|
  if f =~ /^\.\/\.addrs\/([\w_]+)$/
    bar = File.open(f, 'r')
    eval(bar.read)

    $addr_db[$1] = $tmp_db[$1] 
  end
end






addrfile = File.open("addr", 'w')
addrfile.puts "##" + Time.now.to_s + "\n\n"
addrfile.puts '$addr_db = ' + $addr_db.inspect
addrfile.close
