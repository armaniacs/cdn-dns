#
# AS namespace
#

# $Id: as_search.rb,v 1.5 2003/01/31 21:50:34 elca Exp $

require "socket"
require "timeout"

require "cache.rb"
require "util.rb"
require "datatype.rb"

Ra_host = [
  "198.108.0.18",  # whois.ra.net
  "209.244.1.180", # rr.Level3.net
]

Whois_cache = Hash.new

#require "multilog"
#ML = MultiLog.new
#ML.open

# from Michael Neumann (neumann@s-direktnet.de)'s whois.rb
def raw_whois (send_string, host)
  s = TCPsocket.open(array_randomize(host)[0], Service::Whois)
  s.write(send_string + "\n")
  ret = ""
  while l = s.gets
    ret += l
  end
  s.close
  return ret
end

def as_get(str)
  begin
    tmp = nil
    as  = nil
    net = nil

    timeout(30) {
      tmp = raw_whois(str, Ra_host)
    }
    tmp.split("\n").each {
      |i|
      if /^origin:/ =~ i
	as = i.split[1]
      end
      if /^route:/  =~ i
	net = i.split[1]
      end
    }
    if as != nil && net != nil
      return {"route" => net, "as" => as}
    end

    return nil
  rescue
    return nil
  end
end

def as_search(str)
  #p Whois_cache

  netaddrs = [str] + ip_masklist(str)

  # �ޤ�����å����õ��
  netaddrs.each {
    |i|
    if Whois_cache[i] != nil
      ML.log("cached AS: " + i + "=>" + Whois_cache[i]["as"])
      return Whois_cache[i]["as"]
    end
  }

  # Ʊ���׵᤬���椷������ ra.net ���䤤��碌�����椷�ʤ��褦��
  # ��å����Ƥ�����
  Whois_cache[str] = {
    "timeout" => Time.now.to_i + 600,   # 10ʬ
    "as"      => "default"
  }


  # ra.net ���䤤��碌����̤�����줿���Ϥ��η�̤ǥ���å�����񤭤��롣
  tmp = as_get(str)
  if tmp != nil
    Whois_cache.delete(str)

    as  = tmp["as"]
    net = tmp["route"]

    ML.log("add AS cache: " + net + "=>" + as)
    Whois_cache[net] = {
      "timeout" => Time.now.to_i + 10800, # 3����
      "as"      => as
    }
    return tmp["as"]
  end

  # ���ޤ��䤤��碌�η�̤������ʤ����ϥ���å���򤽤Τޤޤˤ���
  # nil ���֤���
  ML.log("add NULL AS cache: " + str + "=>default")

  return nil
end

# ���Ū�˸Ť����Ƥ���
Thread.start do
  loop do
    sleep 15
    # ����å���˻������¤򤫤���
    cache_timeout(Whois_cache, "as timeout: ")

    sleep 15
    # ����å���˥��������¤򤫤���
    cache_reduction(Whois_cache, 2000, "as overflow: ")

  end
end

# end
