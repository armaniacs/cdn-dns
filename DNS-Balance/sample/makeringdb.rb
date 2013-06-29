#
# RING Server 向け addr ファイル作成スクリプト
#

# usage:
#   ruby makeringdb.rb | sort | uniq | ruby makedb.rb > addr

require 'md5'

servers = {
  "core.ring.gr.jp" => "150.29.9.6", # -> aist
  "ring.etl.go.jp"  => "192.50.77.195",
  "ring.aist.go.jp" => "150.29.9.6",
  "ring.asahi-net.or.jp" => "202.224.39.15",
  "ring.crl.go.jp" => "133.243.3.209",
  "ring.astem.or.jp" => "133.18.72.10",
  "ring.jah.ne.jp" => "210.162.2.10",
  "ring.exp.fujixerox.co.jp" => "210.154.149.34",
  "ring.so-net.ne.jp" => "210.132.247.108",
  "ring.ip-kyoto.ad.jp" => "202.245.159.10",
  "ring.iwate-pu.ac.jp" => "210.156.40.3",
  "ring.shibaura-it.ac.jp" => "202.18.64.24",
  "ring.ocn.ad.jp" => "202.234.233.10",
  "ring.htcn.ne.jp" => "210.167.0.75",
  "ring.omp.ad.jp" => "210.159.1.54",
  "ring.jec.ad.jp" => "210.161.150.21",
  "ring.tains.tohoku.ac.jp" => "130.34.246.198",
  "ring.toyama-ix.net" => "210.167.6.130",
  "ring.toyama-u.ac.jp" => "160.26.1.22",
  "ring.edogawa-u.ac.jp" => "210.235.130.17",
  "ring.data-hotel.net" => "210.81.45.28",
  "ring.yamanashi.ac.jp" => "133.23.250.240"
}

for i in servers.keys
#  if i == "core.ring.gr.jp"  # -> aist
#    next
#  end

  md5 = MD5.new(`lynx -source http://core.ring.gr.jp/ring/#{i}.gif`)
  digest = md5.hexdigest

  case digest
  when "075d7eb92a087ecd965b14ead6ad46d0"
    badness = 0
  when "6e57d1300e96c5527599af35b823cde4"
    badness = 700
  when "addace7a5a938cc5d417d502ea351894"
    badness = 1000
  when "b24abb8540c3a3f930c97d1c48730683"
    badness = 1700
  when "b3e87be0b7d8fd7abd160f78dcf82051"
    badness = 2200
  when "aee8c28793e407b274304070f597fcea"
    badness = 3400
  when "9eadd49cb2e8814030b115299aff0fff"
    badness = 5800
  when "f15789c3897e2eaf08ebf5dd048f9702"
    badness = 6900
  when "4796929e047f2984872a9b8b7f4ad933"
    badness = 8100
  when "0f66ec5998ba979fcd1bf17e0b983e21"
    badness = 9500
  when "8d0b589ed3ed7466ce9ab7479bc0969c"
    badness = 10000      # server down
  else
    badness = 10000
    print "# other\n"
  end

  print "# #{i} #{digest}\n"
  print "default,www.ring.gr.jp,#{servers[i]},#{badness}\n"
  print "default,ftp.ring.gr.jp,#{servers[i]},#{badness}\n"
end

for i in servers.keys
  print "# #{i}\n"
  print "default,#{i},#{servers[i]},0\n"
end

print "# openlab\n"
print "default,openlab.ring.gr.jp,150.29.9.5,0\n"

print "#end\n"

# end
