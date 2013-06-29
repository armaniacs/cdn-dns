#!/usr/bin/env ruby

require 'drb/drb'

class StoreSurrogateLocal
  def initialize
    @ss = Hash.new
  end

  def dstatus(host, code, ctime=Time.now)
    if @ss[host] && @ss[host][2]
      failCount = @ss[host][2]
    else
      failCount = 0
    end
    if code >= 400
      failCount += 1
    elsif code >= 200 && code < 300
      failCount = 0
    end
    @ss[host] = [code.to_i, Time.now, failCount]
  end

  def dcode(host)
    return @ss[host]
  end

end

## normal drb test
begin
  there = DRbObject.new_with_uri('druby://localhost:38100') 
  puts "** druby test **"
  there.dstatus("127.0.0.2", 100)
rescue 
  p $!
  puts "** localtest **"
  there = StoreSurrogateLocal.new
  there.dstatus("127.0.0.2", 100)
end

there.dstatus("127.0.0.2", 402)
there.dstatus("127.0.0.4", 404)

p there.dcode("127.0.0.2")
there.dstatus("127.0.0.2", 402)
p there.dcode("127.0.0.2")
p there.dstatus("127.0.0.2", 402, Time.now - 5)


there.dstatus("127.0.0.2", 200)
p there.dcode("127.0.0.2")

p there.dcode("202.158.214.106") #=>nil
p there.dcode("195.178.192.118") #=>nil
h4 = there.dcode("127.0.0.4")

hoge = {
  '10.100.0.1' => 201,
  '10.100.0.2' => 202,
  '300.100.0.2' => 404,
  'no ip' => 404,
}
p hoge
there.bulk_status(hoge)
p there.dcode("10.100.0.1") #=>201
p there.dcode("10.100.0.2") #=>202
p there.dcode("300.100.0.2") #=>nil
p there.dcode("no ip") #=>nil

p bg1 = there.bulk_get
there.bulk_put(bg1)


if h4[1] + 1 < Time.now
  puts "must check"
else
  puts "no need to check" # ok
end

sleep 1

if h4[1] + 1 < Time.now
  puts "must check" # ok
else
  puts "no need to check"
end

#drbssl test

puts "** drbssl test **"

require 'drb/ssl'
there2 = "drbssl://localhost:38201"

config = {
  :SSLVerifyMode => OpenSSL::SSL::VERIFY_PEER,
  :SSLCACertificateFile => "/Users/yaar/.cdn-keepd/CA/cacert.pem",
  :SSLPrivateKey =>
    OpenSSL::PKey::RSA.new(File.read("test/test_keypair.pem")),
  :SSLCertificate =>
    OpenSSL::X509::Certificate.new(File.read("test/cert_test.pem")),
}

DRb.start_service nil, nil, config
h = DRbObject.new nil, there2

p h.dcode("127.0.0.2")
