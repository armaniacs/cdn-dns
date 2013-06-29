/var/log/dns_balance.log {
	weekly
	rotate 4
	compress
	missingok
	create 644 nobody nogroup
	postrotate
		kill -HUP `cat /var/run/dns_balance.pid`
	endscript
}
