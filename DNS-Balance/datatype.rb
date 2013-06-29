#
# static data
#
# By: YOKOTA Hiroshi <yokota@netlab.is.tsukuba.ac.jp>

# $Id: datatype.rb,v 1.5 2003/01/31 21:50:34 elca Exp $

module DnsClass
  INET  = "\0\1"
  CS    = "\0\2"
  CHAOS = "\0\3"
  HS    = "\0\4"
  ANY   = "\0\377"
end

module DnsType
  A     = "\0\1"
  NS    = "\0\2"
  CNAME = "\0\5"
  SOA   = "\0\6"
  PTR   = "\0\14"
  HINFO = "\0\15"
  MX    = "\0\17"
  TXT   = "\0\20"
  RP    = "\0\21"
  SIG   = "\0\30"
  KEY   = "\0\31"
  AAAA  = "\0\34"
  SRV   = "\0\41"
  A6    = "\0\46"
  AXFR  = "\0\374"
  ANY   = "\0\377"
end

module Signal
  HUP    =  1
  INT    =  2
  QUIT   =  3
  ILL    =  4
  TRAP   =  5
  ABRT   =  6
  BUS    =  7
  FPE    =  8
  KILL   =  9
  USR1   = 10
  SEGV   = 11
  USR2   = 12
  PIPE   = 13
  ALRM   = 14
  TERM   = 15
  # ???  = 16
  CHLD   = 17
  CONT   = 18
  STOP   = 19
  TSTP   = 20
  TTIN   = 21
  TTOU   = 22
  URG    = 23
  XCPU   = 24
  XFSZ   = 25
  VTALRM = 26
  PROF   = 27
  WINCH  = 28
  IO     = 29
  PWR    = 30
  SYS    = 31
end

module Service
  Whois   = 43
  Domain  = 53
  MDomain = 5353
  DebDomain = 10053
end

# end
