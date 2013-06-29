#!/usr/bin/env ruby
#
# Mirros.masterlist is 
# http://cvs.debian.org/webwml/english/mirror/Mirrors.masterlist?root=webwml&view=co
#
#

require 'rubygems'
require 'activerecord'
require 'resolv'
require File.dirname(__FILE__) + '/../geoip/lib/geoip'


 ActiveRecord::Base.establish_connection(
   :adapter => 'mysql',
   :host => 'localhost',
   :username => 'yaar',
   :database => 'debian_mirror'
 )
 
class Surrogate < ActiveRecord::Base
  validates_uniqueness_of :site
end

def geoip_search_country(str)
  geo = GeoIP.new('/usr/share/GeoIP/GeoIP.dat').country(str)
  return geo[4]
end

def geoip_search_continent(str)
  geo = GeoIP.new('/usr/share/GeoIP/GeoIP.dat').country(str)
  return geo[6]
end

def geoip_sa(str)
  geo = GeoIP.new('/usr/share/GeoIP/GeoIP.dat').country(str)
end


site = ''
site_type = ''
site_bps = ''
country = ''
ipv6 = ''
site_alias = ''
includes = ''
archive_rsync = ''
archive_architecture = ''
archive_http = ''
archive_ftp = ''
archive_upstream = ''

volatile_rsync = ''
volatile_architecture = ''
volatile_http = ''
volatile_ftp = ''
volatile_upstream = ''

ctld = ''
cdn_capable = ''
cdn_volatile_capable = ''
reciprocal = 9999

while(s = gets) 

  site = $1 if s =~ /^Site:\s+(\S+)/
  site_type = $1 if s =~ /^Type:\s+(\S+)/

  country = $1 if s =~ /^Country:\s+(\S+)/
  ipv6 = $1 if s =~ /^IPv6:\s+(\S+)/
  site_alias = $1 if s =~ /^Alias:\s+(\S+)/
  includes = $1 if s =~ /^Includes:\s+(.+)/

  archive_rsync = $1 if s =~ /^X-Archive-rsync:\s+(\S+)/
  archive_architecture = $1 if s =~ /^X-Archive-architecture:\s+(.+)$/
  archive_http = $1 if s =~ /^X-Archive-http:\s+(\S+)/
  archive_ftp = $1 if s =~ /^X-Archive-ftp:\s+(\S+)/
  archive_upstream = $1 if s =~ /^X-Archive-upstream:\s+(\S+)/

  archive_rsync = $1 if s =~ /^Archive-rsync:\s+(\S+)/
  archive_architecture = $1 if s =~ /^Archive-architecture:\s+(.+)$/
  archive_http = $1 if s =~ /^Archive-http:\s+(\S+)/
  archive_ftp = $1 if s =~ /^Archive-ftp:\s+(\S+)/
  archive_upstream = $1 if s =~ /^Archive-upstream:\s+(\S+)/


  volatile_rsync = $1 if s =~ /^X-Volatile-rsync:\s+(\S+)/
  volatile_architecture = $1 if s =~ /^X-Volatile-architecture:\s+(.+)$/
  volatile_http = $1 if s =~ /^X-Volatile-http:\s+(\S+)/
  volatile_ftp = $1 if s =~ /^X-Volatile-ftp:\s+(\S+)/
  volatile_upstream = $1 if s =~ /^X-Volatile-upstream:\s+(\S+)/

  volatile_rsync = $1 if s =~ /^Volatile-rsync:\s+(\S+)/
  volatile_architecture = $1 if s =~ /^Volatile-architecture:\s+(.+)$/
  volatile_http = $1 if s =~ /^Volatile-http:\s+(\S+)/
  volatile_ftp = $1 if s =~ /^Volatile-ftp:\s+(\S+)/
  volatile_upstream = $1 if s =~ /^Volatile-upstream:\s+(\S+)/

  ctld = $1 if s =~ /^Country:\s+(\S\S)/

  if s =~ /^Comments?:\s+.+\s\(?(\d\S+)\s*(M|G)bps/i
    site_bps = $1+$2
  elsif s =~ /^Comments?:\s+.+\s~?(\d\S+)\s*(M|G)bps/i
    site_bps = $1+$2
  elsif s =~ /^Comments?:\s+(\d\S*)\s*(M|G)bps/i
    site_bps = $1+$2
  elsif s =~ /^Comments?:\s+.*(\d\S*)\s*(M|G)bps/i
    site_bps = $1+$2
  end


  if s =~ /^\s*$/

    if site_bps.length > 1
      site_bps.sub!(/,/,'.') 
      if site_bps =~ /(\d\S*)(G|M)/
        speed = $1.to_f
        tani = $2
        if tani == "G"
          speed *= 1000
        end
        s2 = 100000 / speed
        reciprocal = s2.to_i
      end
    else
      reciprocal = 9999
    end
    puts site + ': ' + reciprocal.to_s

    #cdn_capable
    if archive_architecture == "alpha amd64 arm armel hppa hurd-i386 i386 ia64 mips mipsel powerpc s390 sparc" && \
      archive_http == "/debian/" && \
      site_type =~ /(Push-Primary)|(Push-Secondary)|(leaf)/ && \
      includes == ""
      cdn_capable = "yes"
    end

    #cdn_volatile_capable
    if cdn_capable == "yes" && \
      volatile_http == "/debian-volatile/" && \
      site_type =~ /(Push-Primary)|(Push-Secondary)|(leaf)/
      cdn_volatile_capable = "yes"
    end


    surrogate = Surrogate.new do |s|
      s.site = site
      s.site_type = site_type if site_type
      s.site_bps = site_bps if site_bps.length > 1

      s.country = country if country
      s.ipv6 = ipv6 if ipv6
      s.site_alias = site_alias if site_alias
      s.includes = includes if includes

      s.archive_rsync = archive_rsync if archive_rsync
      s.archive_http = archive_http if archive_http
      s.archive_ftp = archive_ftp if archive_ftp
      s.archive_upstream = archive_upstream if archive_upstream
      s.archive_architecture = archive_architecture if archive_architecture

      s.volatile_rsync = volatile_rsync if volatile_rsync
      s.volatile_http = volatile_http if volatile_http
      s.volatile_ftp = volatile_ftp if volatile_ftp
      s.volatile_upstream = volatile_upstream if volatile_upstream
      s.volatile_architecture = volatile_architecture if volatile_architecture

      s.ctld = ctld if ctld
      s.cdn_capable = cdn_capable if cdn_capable == "yes"
      s.cdn_volatile_capable = cdn_volatile_capable if cdn_volatile_capable == "yes"
      s.cdn_capability = reciprocal
    end
    surrogate.save
 #   p surrogate
    #    p surrogate if cdn_volatile_capable == "yes"

    site = ''
    site_type = ''
    site_bps = ''
    country = ''
    ipv6 = ''
    site_alias = ''
    includes = ''

    archive_rsync = ''
    archive_architecture = ''
    archive_http = ''
    archive_ftp = ''
    archive_upstream = ''

    volatile_rsync = ''
    volatile_architecture = ''
    volatile_http = ''
    volatile_ftp = ''
    volatile_upstream = ''

    ctld = ''
    cdn_capable = ''
    cdn_volatile_capable = ''
    reciprocal = 9999

  end
  
end

sa = Surrogate.find(:all, :conditions => ["cdn_capable = ?", "yes"])

sa.each do |s|
  begin
#    s.site_ipaddr = Resolv::getaddress(s.site)
    g1 = geoip_sa(s.site)
    ## ["ftp.fr.debian.org", "212.27.32.66", 74, "FR", "FRA", "France", "EU"]
    s.site_ipaddr = g1[1]
    s.c3 = g1[4]
    s.continent = g1[6]
    s.save
  rescue
    p $!
    s.cdn_capable = "no"
    s.save
  end
  


end
