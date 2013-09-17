#
# DNS Balance
#
# ログ出力
#
# By: YOKOTA Hiroshi <yokota@netlab.is.tsukuba.ac.jp>

# $Id: log_writer.rb,v 1.6 2003/06/13 22:05:38 elca Exp $

require "util.rb"

# ログ出力
def logger(mutex, addr, status, name = "", namespace = "", answers = [])
  out = sprintf("%s:%s:%s:%s",
		addr,
		status,
		name,
		namespace)

  if answers == nil || answers == []
    out += ":"
  else
    s = []
    answers.each {
      |i|
      s.push(sprintf("%d.%d.%d.%d", i[0], i[1], i[2], i[3]))
    }
    out += sprintf(":%s", s.join(" "))
  end
  mutex.log(out)
end

# end
