#!/usr/local/bin/ruby
#
# CSV -> namespace ファイル変換
#

#
# 内容は一行に <アドレス>,<別名> を書く
#
# Usage: sort < input.csv | uniq | make_namespace.rb > namespace.rb
#
# $Id: make_namespace.rb,v 1.2 2002/06/08 16:27:31 elca Exp $

print <<"__EOM__"

$namespace_db = {
__EOM__


while gets
  if $_ =~ /^#/ || $_ =~ /^[ \t]*$/ # コメント
    next
  end

  l = $_.chop.split(",")
  #p l

  print "\t\"", l[0], "\" => \"", l[1], "\",\n"

end

print <<"__EOM__"
}
__EOM__

# end
