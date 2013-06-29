#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# = Script of gae-surrogates.rb
#
# This script gets Debian-CDN-Style JSON data to convert DnsBalance's address file (addr).
#
# Mainly for http://debiancdn.appspot.com/json/alive.
#
# = DEPENDENCY
# 
# rubygems, json, open-uri.
#    You can install json by 'gem install json'. 
#    or
#    get from http://www.ping.de/~flori/json-1.4.3.tgz and ruby install.rb.
#
# = SYNOPSIS
#
# == How to run this script
# 
# ruby gae-surrogates.rb http://check1-tokyo.s.araki.net/status/alive
# ruby gae-surrogates.rb http://debiancdn.appspot.com/json/alive
# ruby gae-surrogates.rb http://localhost:8080/json/alive
#   OR
# ruby gae-surrogates.rb local_file.json
#
# Then, this script makes './addr'.

require 'rubygems'
require 'json'
require 'open-uri'

begin
  if ARGV[0] =~ /^http/
    json = open(ARGV[0]).read
  else
    f = ARGV[0] 
    json = File.open(f, 'r').read
  end
rescue
  p $!
  
end

begin
  pj = JSON.parse(json)
  addr = Hash.new

  pj.each do |hs|
    if hs['_data']
      hs = hs['_data']
    end
    country = hs['country']
    hostname = hs['hostname']
    if addr[country]
    else
      addr[country] = Hash.new
    end
    
    if addr[country][hostname]
    else
      addr[country][hostname] = Array.new
    end
    addr[country][hostname].push([hs['ip'].split('.').map{|x| x.to_i}, hs['preference']])

    continent = hs['continent']
    if addr[continent]
    else
      addr[continent] = Hash.new
    end
    
    if addr[continent][hostname]
    else
      addr[continent][hostname] = Array.new
    end
    addr[continent][hostname].push([hs['ip'].split('.').map{|x| x.to_i}, hs['preference']])


    targetnet = hs['targetnet']
    if addr[targetnet]
    else
      addr[targetnet] = Hash.new
    end
    
    if addr[targetnet][hostname]
    else
      addr[targetnet][hostname] = Array.new
    end
    addr[targetnet][hostname].push([hs['ip'].split('.').map{|x| x.to_i}, hs['preference']])

    if hs['targetasnum']
      targetasnum = 'AS' + hs['targetasnum'].to_s
    end
    if addr[targetasnum]
    else
      addr[targetasnum] = Hash.new
    end
    
    if addr[targetasnum][hostname]
    else
      addr[targetasnum][hostname] = Array.new
    end
    addr[targetasnum][hostname].push([hs['ip'].split('.').map{|x| x.to_i}, hs['preference']])

  end

  addrfile = File.open("addr", 'w')
  addrfile.puts "##" + Time.now.to_s
  addrfile.puts "##" + ARGV[0] + "\n\n"
  addrfile.puts '$addr_db = ' + addr.inspect
  addrfile.close

rescue => ex
  p ex.class
end
