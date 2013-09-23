#!/usr/bin/env make

alive:
	ruby gae-surrogates.rb http://cdncheck1.araki.net/status/alive
	cd DNS-Balance && ln -s ../addr .

dnstest:
	cd DNS-Balance && ruby dns_balance.rb -F -p 10053

