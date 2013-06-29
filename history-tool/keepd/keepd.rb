#!/usr/bin/env ruby

require 'drb'
require 'drb/ssl'
require 'time'
require 'optparse'

forceProcess = false
configFile = ''
pidFile = ''
sslURI = ''
dURI = ''
verBose = false

OptionParser.new do |opt|
  opt.on("-f", "--force", "When some process is existed, kill and start"){|v| forceProcess = true}
  opt.on("-v", "--verbose", "Verbose output"){|v| verBose = true}
  opt.on("-c configFile", "--conf configFile", "Set config file. (default: $HOME/.cdn-keepd/cdn-keepd.conf)"){|v| configFile = v}
  opt.on("-p PIDfile", "--pid-file PIDFile", "Set PID file. (default: /var/run/dns_balance_keepd.ped)"){|v| pidFile = v}
  opt.on("-s sslURI", "--ssl-URI sslURI", "Set URI for drbssl (no default)"){|v| sslURI = v}
  opt.on("-u URI", "Set URI for drb (default: druby://localhost:38100)"){|v| dURI = v}
  opt.parse!(ARGV)
end

if configFile && configFile.size > 0
  if File.exist? configFile
    load configFile
  else
    puts "configFile is not existed."
    exit 1
  end
elsif File.exist? File.expand_path(ENV['HOME'] + "/.cdn-keepd/cdn-keepd.conf")
  load File.expand_path(ENV['HOME'] + "/.cdn-keepd/cdn-keepd.conf")
else
  puts "Please set ~/.cdn-keepd/cdn-keepd.conf"
  $process_file = '/var/run/dns_balance_keepd.pid' unless $process_file
  $uri = "druby://localhost:38100"
end

$process_file = pidFile if (pidFile && pidFile.size > 0)
$sslURI = sslURI if (sslURI && sslURI.size > 0)
$uri = dURI if (dURI && dURI.size > 0)


class StoreSurrogates
  def initialize
    @ss = Hash.new
  end

  def dstatus(host, code, ctime=Time.now)
    if host =~ /\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\z/
    else
      puts "no IPv4 address: #{host}"
      return nil
    end

    if @ss[host] && @ss[host][1] && @ss[host][1] < ctime
      @ss[host][1] = ctime
    end
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
    @ss[host] = [code.to_i, ctime, failCount]
  end

  def dcode(host)
    return @ss[host]
  end

  def bulk_status(hostset)
    puts "## bulk_status"
    hostset.each do |k,v|
      dstatus(k, v.to_i)
    end
  end

  def bulk_get
    return @ss
  end

  # dstatus(host, code, ctime=Time.now)
  def bulk_put(statusset) # XXX
    puts "## bulk_put"
    statusset.each do |k,v|
      begin
        if v[1] > @ss[k][1]
          puts "### put: " + k
          @ss[k] = v
        end 
      rescue
        p $!
      end
    end
  end

end


if File.exist?($process_file)
  print "Other daemon running. pidfile is #{$process_file}\n"
  old_pid = File.open($process_file).read.chomp.to_i
  if forceProcess
    puts "kill old process"
    Process.kill(15, old_pid)
    sleep 1
  else
    exit 1
    fail
  end
end

fork{
  Process::setsid
  fork{
    pid = Process.pid
    print "Start #{$0} running pid is #{pid}\n"
    pidfile = open($process_file, "w+")
    pidfile.write(pid)
    pidfile.flush
    
    begin
      Process::UID.eid=65534
    rescue
      puts $!
      puts "run by uid #{Process.euid}"
    end

    STDIN.reopen("/dev/null", "r+")
    STDOUT.reopen("/dev/null", "w") unless verBose
    STDERR.reopen("/dev/null", "w") unless verBose

    ss = StoreSurrogates.new

    if $uri
      Thread.new do
        DRb.start_service($uri,ss)
        DRb.thread.join
      end
    end

    if $sslUri && $drb_config
      DRb.start_service $sslUri, ss, $drb_config
      DRb.thread.join
    end

    sleep
  }
}
