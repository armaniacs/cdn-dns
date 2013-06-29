#!/usr/bin/make

all: ip city asnum

backup:
	cp *.dat old

ip:
	cp GeoIP.dat old
	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz && gunzip -f GeoIP.dat.gz

city:
	cp GeoLiteCity.dat old
	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gunzip -f GeoLiteCity.dat.gz

asnum:
	cp GeoIPASNum.dat old
	wget http://geolite.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz && gunzip -f GeoIPASNum.dat.gz
