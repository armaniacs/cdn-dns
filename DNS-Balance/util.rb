#
# DNS Balance
#
# 雑用
#
# By: YOKOTA Hiroshi <yokota@netlab.is.tsukuba.ac.jp>

# $Id: util.rb,v 1.7 2003/06/13 22:05:38 elca Exp $

# DNS パケット中の RR 名を人間に読みやすい形式に変換
def dnsstr_to_str(dnsstr)
  arr = []
  c = 0

  while TRUE
    break if dnsstr.size <= c
    break if dnsstr[c] == 0

    arr.push(dnsstr[c+1, dnsstr[c]])
    c += dnsstr[c]+1
  end

  return arr.join(".")
end

def str_to_dnsstr(str)
  return str.split(".").collect {
    |i|
    sz = min(i.size, 63) # less than 63 chars for each domain

    sz.chr + i[0,sz]
  }.join("") + "\0"
end

# 文字列を DNS TXT RR にする
def str_to_dnstxt(str)
  return str_split(str,127).collect {|i| i.size.chr + i}.join("")
end

# IP アドレス表記からそれに見合った4バイトの文字列を生成
#
# ex) "127.0.0.1" => "\x7f\x0\x0\x1"
def str_to_ipstr(str)
  return str.split(".").collect{|i| i.to_i}.pack("C4")
end

def ipstr_to_str(ipstr)
  return ipstr.unpack("C4").join(".")
end

def ipstr_array_to_str(arr)
  return arr.collect{|i| ipstr_to_str(i)}.join(" ")
end

def str_to_ip6str(str)
  tmp = str.split("::")

  laddr = raddr = []

  if tmp[0] != nil
    laddr = tmp[0].split(":").collect{|i| i.hex}
  end

  if tmp[1] != nil
    raddr = tmp[1].split(":").collect{|i| i.hex}
  end

  addr6 = laddr + ([0] * (8 - (laddr.size + raddr.size))) + raddr

  return addr6.pack("n8")
end

def ip6str_to_str(str)
  return str.unpack("H4" * 8).join(":") #.gsub(/:0?0?0?/, ":")
end
    

# 文字列を指定文字数で区切る
def str_split(str, num)
  a = Array.new
  (0...((str.length + num - 1)/num).to_i).each {
    |i|
    a << str[i * num, num]
  }
  return a
end

# ipstr に対してビットマスクをかける
def ipstr_mask(ipstr, mask)
  n = ipstr.unpack("N")[0] & (0xffffffff << (32 - mask))
  return [n].pack("N")
end

#
def ip_mask(str, mask)
  ipstr = str_to_ipstr(str)
  ans   = ipstr_mask(ipstr, mask)
  return ipstr_to_str(ans)
end

# IP アドレスの /32 から /1 までのマスクをかけたアドレスのリストを返す
def ip_masklist(str)

  netaddrs = []
  (0..31).each {
    |i|
    mask = 32-i

    netaddrs << (ip_mask(str, mask) + "/" + mask.to_s)
  }

  return netaddrs
end

def domain_makelist(name)
  n = name.split(".")
  ret = []

  (0...(n.size)).each {
    |i|
    ret << n[i...(n.size)].join(".")
  }

  return ret
end

# add "unique" flag to dns class
def unique_add(str)
  tmp = str.dup
  tmp[0] |= 0x80
  return tmp
end

def unique_drop(str)
  tmp = str.dup
  tmp[0] &= 0x7f
  return tmp
end


#
def min(a, b)
  return (if a < b then a else b end)
end

def max(a, b)
  return (if a < b then b else a end)
end

# 配列をランダムに並べ変える
def array_randomize(arr)
  return []  if arr.size == 0
  return arr if arr.size == 1

  h = Hash.new
  (0...arr.size).each {
    |i|
    p = rand()
    h[p] = i
  }

  tmp = Array.new
  h.sort.each {
    |i|
    tmp << i[1]
  }

  ret = tmp.collect {
    |i|
    arr[i]
  }

  return ret
end

# end
