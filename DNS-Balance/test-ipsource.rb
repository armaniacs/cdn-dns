#!/usr/bin/ruby
# -*- coding: utf-8 -*-

$fgeoip = File.dirname(__FILE__) + '/../maxmind/GeoIP.dat'
$fgeoipasn = File.dirname(__FILE__) + '/../maxmind/GeoIPASNum.dat'

require 'datatype.rb'
require 'util.rb'
require 'namespace.rb'
require 'addrdb.rb'
require File.dirname(__FILE__) + '/../geoip/lib/geoip'
$LOAD_PATH.freeze ## for geoip

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
      # RFC1918 / プライベートアドレスはどこの AS にも属していない
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

def main
  if ARGV.size == 0
    puts "try.rb fromIP"
    exit
  end

  load("addr")

  name = "deb.cdn.araki.net"
  namespace = select_namespace(ARGV[0], name)
  puts namespace
end

OPT = Hash.new
OPT["country"] = true
OPT["continent"] = true
OPT["as"] = true

main
