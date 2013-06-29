#!/usr/local/bin/ruby
#
# CSV -> namespace �ե������Ѵ�
#

#
# ���Ƥϰ�Ԥ� <���ɥ쥹>,<��̾> ���
#
# Usage: sort < input.csv | uniq | make_namespace.rb > namespace.rb
#
# $Id: make_namespace.rb,v 1.2 2002/06/08 16:27:31 elca Exp $

print <<"__EOM__"

$namespace_db = {
__EOM__


while gets
  if $_ =~ /^#/ || $_ =~ /^[ \t]*$/ # ������
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
