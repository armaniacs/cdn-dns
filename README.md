cdn-dns
=======

DNS part of cdn.debian.net 

Install
-----------

1. install ruby1.8 (Ruby Enterprise Edition is preferred).
1. gem install geoip json

Prepare geoip database
-------------------------

`cd maxmind && makefile`


Prepare data
--------------

`$ make prepare`

1. checks the http://cdncheck1.araki.net/status/alive
1. write the file (./addr)
1. link DNS-Balance/addr -> ./addr

test run
---------------

1. open two terminals.(T1 and T2)
1. At T1, `$ make dnstest`. Start dns_balance.rb running in Foreground mode and waiting port 10053.
1. At T2, `$ dig @127.0.0.1 -p 10053 deb.cdn.araki.net`. If you get one or more IP address as a result, your test is succeeded.
=======
Prepare condition for run
----------------------------

1. `cd DNS-Balance`
1. install rubygems 
1. install geoip with `# bundle install`


