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


sa = Surrogate.find(:all, :conditions => ["cdn_capable = ?", "yes"],
                    :order => 'c3,cdn_capability')

begin
  Dir.mkdir(".country_addrs")
  Dir.mkdir(".continent_addrs")
rescue
end
tmp_c = String.new

tmp_sc = Hash.new
tmp_scontinent = Hash.new

sa.each do |s|

  if tmp_sc["#{s.c3}"]
    tmp_sc["#{s.c3}"] += " '#{s.site_ipaddr}' => '#{s.cdn_capability}',"
  else
    tmp_sc["#{s.c3}"] = " '#{s.site_ipaddr}' => '#{s.cdn_capability}',"
  end

  if tmp_scontinent["#{s.continent}"]
    tmp_scontinent["#{s.continent}"] += " '#{s.site_ipaddr}' => '#{s.cdn_capability}',"
  else
    tmp_scontinent["#{s.continent}"] = " '#{s.site_ipaddr}' => '#{s.cdn_capability}',"
  end
end

time0 = Time.now.to_s

tmp_sc.each do |k,v|
  foo = File.open(".country_addrs/#{k}_deb_cdn_araki_net.rb", 'w')
  foo.puts "# generated by #{__FILE__}"
  foo.puts "# generated at #{time0}"
  foo.puts "$surrogates = {" + v + "}"
end

tmp_scontinent.each do |k,v|
  foo = File.open(".continent_addrs/#{k}_deb_cdn_araki_net.rb", 'w')
  foo.puts "# generated by #{__FILE__}"
  foo.puts "# generated at #{time0}"
  foo.puts "$surrogates = {" + v + "}"
end
# $surrogates = {
#  '203.178.137.175' => '9000', # naist
# }
