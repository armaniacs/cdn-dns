#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
# DNS Balance --- 動的負荷分散を行なう DNS サーバ
#
# By: YOKOTA Hiroshi <yokota@netlab.is.tsukuba.ac.jp>
# $Id: dns_balance.rb,v 1.25 2003/06/13 22:07:27 elca Exp $
## Modify for debian cdn
## By ARAKI Yasuhiro <ar@debian.org>
if ENV["ROOT"] == nil
  warn("\"ROOT\" environment is recommended. Use current directory in this time.")
  PREFIX = "."
else
  PREFIX = ENV["ROOT"]
  $LOAD_PATH.unshift(PREFIX)
end

$:.unshift(File.dirname(__FILE__)) # ruby2.0

$process_file = '/var/run/dns_balance.pid'
$logfile = '/var/log/dns_balance.log'

$fgeoip = File.dirname(__FILE__) + '/../maxmind/GeoIP.dat'
$fgeoipasn = File.dirname(__FILE__) + '/../maxmind/GeoIPASNum.dat'

require 'socket'
require 'thread'
require 'optparse'

require 'datatype.rb'
require 'multilog.rb'
require 'log_writer.rb'
require 'util.rb'

require 'namespace.rb'
require 'addrdb.rb'

require File.dirname(__FILE__) + '/../geoip/lib/geoip'
$LOAD_PATH.freeze ## for geoip

#####################################################################
# ������若�九��臂������紊�
class DnsNotImplementedError < StandardError ; end
class DnsTruncatedError      < StandardError ; end
class DnsNoQueryError        < StandardError ; end
class DnsNoMoreResourceError < StandardError ; end

class DnsNoErrorError < StandardError ; end

Socket::do_not_reverse_lookup = true

###################################################################
# �∽��

# DNS パ�宴��トから莖������内絎鴻�����蟹問������帥�ゃ�������蟹問����������������鴻��取り�冴��
def parse_packet(packet)
  (number, flags, num_q, ans_rr, ort_rr, add_rr, str) =  packet.unpack("a2 a2 a2 a2 a2 a2 a*")

  if num_q != "\0\1"
    ML.log("Q must be 1")
    return [nil, nil, nil]
  end

  qlen = str.split("\0")[0].length + 1

  (q, q_type, q_class) = str.unpack("a#{qlen} a2 a2")

  return [q, q_type, q_class]
end

# �����������ゃ�≪�潟����������宴��菴�す
def get_client_data(cli)
  (family, port, fqdn, ipaddr) = cli
  return {"family" => family, "port" => port, "fqdn" => fqdn, "addr" => ipaddr}
end

# �����������ゃ�≪�潟��のIP�≪��������鴻��������ｃ�������膈�内絎鴻��紊�える篋�が�堺�ャ��
# 名前腥咲��を�御��。綵������������障����������������れば "default" ������������
def select_namespace(addrstr, name)

  netaddrs = [addrstr] + ip_masklist(addrstr)

  # custom namespace
  netaddrs.each {
    |i|
    if $namespace_db[i]                  != nil &&
	$addr_db[$namespace_db[i]]       != nil &&
	$addr_db[$namespace_db[i]][name] != nil
      return $namespace_db[i]
    end
  }

  # address number namespace
  netaddrs.each {
    |i|
    if $addr_db[i]        != nil &&
	$addr_db[i][name] != nil
      return i
    end
  }

  # AS namespace
  if OPT["as"] &&
      # RFC1918 / プ������ゃ���若���≪��������鴻������������の AS �������絮�し��������������
      ip_mask(addrstr,  8) != "10.0.0.0"      &&
      ip_mask(addrstr, 12) != "172.16.0.0"    &&
      ip_mask(addrstr, 16) != "192.168.0.0"   &&
      ip_mask(addrstr, 21) != "204.152.184.0" &&
      addrstr              != "127.0.0.1"

    as = geoip_search_asn(addrstr)
    if as                  != nil &&
	$addr_db[as]       != nil &&
	$addr_db[as][name] != nil
      return as
    end
  end

  # country by GeoIP
  if OPT["country"] &&
      ip_mask(addrstr,  8) != "10.0.0.0"      &&
      ip_mask(addrstr, 12) != "172.16.0.0"    &&
      ip_mask(addrstr, 16) != "192.168.0.0"   &&
      ip_mask(addrstr, 21) != "204.152.184.0" &&
      addrstr              != "127.0.0.1"
    
    as = geoip_search_country(addrstr)

    if as                  != nil &&
	$addr_db[as]       != nil &&
	$addr_db[as][name] != nil
      return as
    end
  end

  # continent: AS, EU, SA, AF, OC, NA
  # continent by GeoIP
  if OPT["continent"] &&
      ip_mask(addrstr,  8) != "10.0.0.0"      &&
      ip_mask(addrstr, 12) != "172.16.0.0"    &&
      ip_mask(addrstr, 16) != "192.168.0.0"   &&
      ip_mask(addrstr, 21) != "204.152.184.0" &&
      addrstr              != "127.0.0.1"
    
    as = geoip_search_continent(addrstr)

    if as                  != nil &&
	$addr_db[as]       != nil &&
	$addr_db[as][name] != nil
      return as
    end
  end


#  return "default"
  return "NA"
end



def geoip_search_country(str)
  geo = GeoIP.new($fgeoip).country(str)
  return geo.nil? ? nil : geo[4]
end

def geoip_search_continent(str)
  geo = GeoIP.new($fgeoip).country(str)
  return geo.nil? ? nil : geo[6]
end

def geoip_search_asn(str)
  geo = GeoIP.new($fgeoipasn).asn(str)
  return geo.nil? ? nil : geo[0]
end


# 重�帥�ゃ��紊��違�������め�����；を篏�る
def make_rand_array(namespace, name)
  rnd_max = 0
  rnd_slesh = []

  $addr_db[namespace][name].each {
    |i|
	 if i[1] >= 10000
         	next
         else
    		rnd_max = rand(rnd_max).to_i + (10000 - min(10000, i[1])) # badness �������紊у�ゃ�� 10000
    		rnd_slesh.push(rnd_max)
	end
  }
  return [rnd_max, rnd_slesh]
end

# 重�帥�ゃ��箙掩�違�ч�御��
def select_rand_array(namespace, name, size)
  (rnd_max, rnd_slesh) = make_rand_array(namespace, name)

  if rnd_max == 0  # ������������������鴻��の Badness が 10000 だ�ｃ��
    return []
  end

  arr = []
  (0...size).each {
    |i|
    rnd = rand(rnd_max)

    (0...rnd_slesh.size).each {
      |j|

      if rnd <= rnd_slesh[j]
	arr.push(j)
	break
      end
    }
  }

  return arr
end

# パ�宴��ト���������綵��с���с��ク
def check_packet(q, q_type, q_class)
  # �障�若�活拶送������＜��
  if q_type == DnsType::AXFR
    ML.log("AXFR: " + q.dump + ":" + q_type.dump + ":" + q_class.dump)
    raise DnsNotImplementedError
  end

  # IP(UDP) ������水��け篁�け
  if !(q_class == DnsClass::INET || q_class == DnsClass::ANY)
    ML.log("noIP: " + q.dump + ":" + q_type.dump + ":" + q_class.dump)
    raise DnsNoQueryError
  end

  # 篏睡�������������������絖�がある
  if (q =~ /[()<>@,;:\\\"\.\[\]]/) != nil
    ML.log("char: " + q.dump + ":" + q_type.dump + ":" + q_class.dump)
    raise DnsNoQueryError
  end

end

def check_type(q, q_type, q_class, namespace)

  # ������潟�若����������������るが�帥�ゃ��が違う
  if q_type != DnsType::A &&
      q_type != DnsType::ANY &&
      $addr_db[namespace] != nil &&
      $addr_db[namespace][dnsstr_to_str(q).downcase] != nil
    ML.log("noT: " + q.dump + ":" + q_type.dump + ":" + q_class.dump)
    raise DnsNoErrorError
  end

  # A/ANY ������潟�若��������水��け篁�け
  if q_type != DnsType::A && q_type != DnsType::ANY
    ML.log("noA: " + q.dump + ":" + q_type.dump + ":" + q_class.dump)
    raise DnsNoQueryError
  end
end

def run
  #
  # �≪��������鴻���若�帥���若�鴻�������的�贋��
  #
  $t_db = Thread::start {
    loop {
      if test(?r, PREFIX + "/addr") || test(?r, "./addr")
        begin
          load("addr")

          ML.log("reload")
        rescue NameError,SyntaxError,Exception
          p $! # XXX
          ML.log("reload failed")
        end
      end
      sleep(2*60) # 5 分罸�������贋��
    }
  }

    $gs = UDPSocket::new()
    sockaddr = (if OPT["i"] == nil then Socket::INADDR_ANY else OPT["i"] end)
    sockaddr = '0.0.0.0' if sockaddr == 0

    if OPT["port"]
      $gs.bind(sockaddr, OPT["port"].to_i)
    else
      $gs.bind(sockaddr, Service::Domain)
    end
    begin
      Process::UID.eid=65534
    rescue
      puts $!
      puts "run by uid #{Process.euid}"
    end


  #
  # �＜�ゃ�潟������若��
  #
  loop {
    (packet, client) = $gs.recvfrom(1024)

    $t_resolv = Thread.start {
      $SAFE = 2
      begin
        client_data = get_client_data(client)
        (q, q_type, q_class) = parse_packet(packet)
        check_packet(q, q_type, q_class) # -> NoQuery, NotImpl

        name      = dnsstr_to_str(q).downcase
        namespace = select_namespace(client_data["addr"], name)

        if $addr_db[namespace][name].nil?
          _namespace = namespace
          namespace = "JPN"
          namespace = "default" if $addr_db[namespace][name].nil?
          ML.log("fallback: from #{_namespace} to #{namespace}")
        end

        check_type(q, q_type, q_class, namespace)

        if $addr_db[namespace][name].size > 1  # -> NoMethodError -> NoQuery
          size = 8
        else
          size = 1
        end

        a1 = select_rand_array(namespace, name, size)
        h1 = a1.inject(Hash.new(0)) { |r, e| r[e] += 1; r }
        a2 = h1.to_a.sort{|a, b| b[1] <=> a[1]}
        a3 = Array.new
        count = 0
        a2.each do |n1|
          a3.push(n1.first)
          count += n1.last
          break if count > 5
        end

        a_array = a3
        if a_array.size == 0
          raise DnsNoMoreResourceError
        end

        # 菴�膈�生成
        r = packet[0,12] + q + q_type + q_class
        r[2] |= 0x84  # answer & authenticated
        r[3] = 0      # no error

        ans_addrs = []
        a_array.each {
          |i|
          addr = $addr_db[namespace][name][i][0]
          ans_addrs.push(addr)   # ������医�阪��用

          # TTL �御��。菴�い所がある篋�が分か�ｃ�������る������� TTL を�激��する
          if (a_array.size == 1)
            ### ttl = "\0\0\x0e\x10" # 1時間 # out by ar@debian.org
            ttl = "\0\0\0\x3c"   # 60腱�
          else
            ttl = "\0\0\0\x3c"   # 60腱�
          end

          # 菴�膈�生成。 ��������祉��トは 0x000c
          r += "\xc0\x0c" + DnsType::A + DnsClass::INET + ttl + "\0\4" + addr.pack("CCCC")
        }

        # 菴�膈�������違���祉��ト
        r[6,2] = [a_array.size].pack("n")
        r[8,4] = "\0\0\0\0"

        # �潔��ぎたら削る
        if r.length > 512
          raise DnsTruncatedError
        end

        status = "ok"

      rescue DnsNotImplementedError
        r = packet[0,12] + q + q_type + q_class
        r[2] |= 0x80  # answer
        r[2] &= ~0x04 # not authenticated
        r[3] = 0
        r[3] |= 0x04  # not implemented error
        r[6,6] = "\0\0\0\0\0\0"
        status = "NotImpl"

      rescue DnsTruncatedError
        # �潔��ぎる時��������ｃ�������������違��腴��������
        r = r[0,512]
        r[2] |= 0x02
        status = "Truncated"

      rescue DnsNoErrorError
        r = packet[0,12] + q + q_type + q_class
        r[2] |= 0x84  # answer & authenticated
        r[3] = 0      # no error

        r[6,6] = "\0\0\0\0\0\0"

        status = "NoError"

      rescue DnsNoQueryError,DnsNoMoreResourceError,NoMethodError,StandardError
        r = packet[0,12] + q + q_type + q_class
        r[2] |= 0x84  # answer & authenticated
        r[3] = 0
        r[3] |= 0x03  # name error
        r[6,6] = "\0\0\0\0\0\0"
        status = "NoQuery"

      rescue
        # ここ�����������ャ��������������
        r = packet[0,12] + q + q_type + q_class
        r[2] |= 0x80  # answer
        r[2] &= ~0x04 # not authenticated
        r[3] = 0
        r[3] |= 0x05  # query refused error
        r[6,6] = "\0\0\0\0\0\0"
        status = "other"
      end

      #print packet.dump, "\n"
      #print r.dump, "\n"
      #p q

      $gs.send(r, 0, client_data["addr"], client_data["port"])

      logger(ML, client_data["addr"], status, name, namespace, ans_addrs)

    }
  }

end



######################################################################
# main

srand()

OPT = Hash::new
OptionParser::new {
  |opt|
  opt.on("-i ADDR", String, "Listen IP address (default:0.0.0.0)") {
    |o|
    OPT["i"] = o;
  }
  opt.on("-p PORT", String, "Listen UDP PORT number (default:53)") {
    |o|
    OPT["port"] = o;
  }
  opt.on("--logfile filename", String, "Set logfile (default: #{$logfile})") {
    |o|
    OPT["logfile"] = true
    $logfile = o;
  }
  opt.on("--geoip-file filename", String, "Set logfile (default: #{$fgeoip})") {
    |o|
    $fgeoip = o;
  }
  opt.on("--geoip-asn-file filename", String, "Set logfile (default: #{$fgeoipasn})") {
    |o|
    $fgeoipasn = o;
  }
  opt.on("--geoip", "Enable GeoIP ") {
    OPT["country"] = true
    OPT["continent"] = true
    OPT["as"] = true
  }
  opt.on("--no-geoip", "Disable GeoIP ") {
    OPT["country"] = false
    OPT["continent"] = false
    OPT["as"] = false
    OPT["nogeoip"] = true
  }
  opt.on("--country", "Enable Country by GeoIP ") {
    OPT["country"] = true
  }
  opt.on("--continent", "Enable Continent by GeoIP ") {
    OPT["continent"] = true
  }
  opt.on("--no-as", "Disable AS namespace") {
    OPT["as"] = false
  }
  opt.on("-F", "Unfork (test purpose)") {
    OPT["unfork"] = true
  }
  opt.on_tail("-h", "--help", "Show this help message and exit") {
    STDERR.printf("%s", opt.to_s)
    exit(111)
  }
  opt.parse!
}
unless OPT["nogeoip"] == true
  OPT["country"] = true
  OPT["continent"] = true
  OPT["as"] = true
end

OPT.freeze



unless File.exist? $fgeoip
  puts $fgeoip + ' is not exist.'
  puts "Please set MaxMind's GeoIP data file."
  puts "Download from http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry"
  puts File.dirname(__FILE__) + '/../maxmind/GeoIP.dat'
  exit 0
end

unless File.exist? $fgeoipasn
  puts $fgeoipasn + ' is not exist.'
  puts "Please set MaxMind's GeoIPASNum data file."
  puts "Download from http://geolite.maxmind.com/download/geoip/database/asnum/"
  puts File.dirname(__FILE__) + '/../maxmind/GeoIPASNum.dat'
  exit 0
end


ML = MultiLog::new

def srun
  if OPT["unfork"]
    if OPT["logfile"]
      fd = open($logfile, "w")
      ML.open(fd)
    else
      ML.open
    end
    ML.log("dir: " + PREFIX)
    ML.log("start")
    print "Start #{$0} running in Foreground mode.\n"
    run
  else
    fd = open($logfile, "w")
    File.chown(65534,65534,$logfile)

    ML.open(fd)
    ML.log("dir: " + PREFIX)
    ML.log("start")
    Process.fork do
      if File.exist?($process_file)
        print "Other daemon running. pidfile is #{$process_file}\n"
        old_pid = File.open($process_file).read.chomp.to_i
        exit 1
        fail
      end
      pid = Process.setsid
      print "Start #{$0} running pid is #{pid}\n"
      pidfile = open($process_file, "w+")
      pidfile.write(pid)
      pidfile.flush
      trap("SIGINT"){ exit! 0 }
      trap("SIGTERM"){ exit! 0 }

#      [ STDIN, STDOUT, STDERR ].each do |io|
      [ STDIN, STDOUT ].each do |io|
        io.reopen("/dev/null", "r+")
      end
      run
    end
  end

end ## srun

trap("SIGHUP"){
  ML.log("SIGHUP")
  begin
    Thread.kill $t_db
    Thread.kill $t_resolv
  rescue
    p $!
  end
  ML.log("close")
  ML.close
  srun
}

srun
