#!/usr/local/bin/ruby
#
# CSV -> addr ファイル変換
#
# By: YOKOTA Hiroshi <yokota@netlab.is.tsukuba.ac.jp>

#
# 入力内容は sort されている事
# 内容は一行に <振り分けタグ>,<ホスト名>,<IPアドレス>,<Badness> を書く
#
# Usage: sort < input.csv | uniq | makedb.rb > addr
#

# $Id: makedb.rb,v 1.7 2002/06/08 16:27:31 elca Exp $

print <<"__EOM__"

$addr_db = {
__EOM__


l0 = ""
l1 = ""
l2 = ""
l3 = ""

while gets
  if $_ =~ /^#/ # コメント
    next
  end

  l = $_.chop.split(",")

  if (l1 != l[1] && l1 != "") || (l0 != l[0] && l0 != "")
    print "\t\t],\n"
  end
  if l0 != l[0] && l0 != ""
    print "\t},\n"
  end

  if l0 != l[0]
    print "\t\"", l[0], "\" => {\n"
  end
  if l1 != l[1] || l0 != l[0]
    print "\t\t\"", l[1], "\" => [\n"
  end
  if l2 != l[2] || l1 != l[1] || l0 != l[0]
    print "\t\t\t[[", l[2].tr(".",","), "], ", l[3], "],\n"
  end


  l0 = l[0]
  l1 = l[1]
  l2 = l[2]
  l3 = l[3]
end

print <<"__EOM__"
\t\t],
\t},
}

__EOM__

# end
