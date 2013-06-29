#
# "syslog" like log interface for multilog
#

# $Id: multilog.rb,v 1.4 2002/10/05 16:29:57 elca Exp elca $

=begin
  multilog.rb - Syslog like log interface for DJB multilog
=end

require "thread"

=begin
MultiLog#open(port = $stdout)
  Open log stream
Multilog#log(string)
  Put string to log stream
Multilog#close
  Close log stream
=end

class MultiLog

  def initialize()
    @loglock = nil
    @outport = nil
  end

  def open(port = $stdout)
    raise RuntimeError if @loglock != nil
    raise RuntimeError if !port.is_a?(IO)

    @loglock = Mutex.new()
    @outport = port
  end

  def log(str)
    raise RuntimeError if !opened?()

    @loglock.synchronize do
      @outport.print(Time.now.to_s + ' ' + str + "\n")
      @outport.flush
    end
  end

  def close()
    @loglock = nil
    @outport = nil
  end

  def opened?()
    if @loglock != nil
      return true
    else
      return false
    end
  end

  def reopen(port = $stdout)
    if opened?()
      close()
    end

    open(port)
  end

  #
  def panic(str)
    log("panic: " + str)
  end
  def crit(str)
    log("crit: " + str)
  end
  def info(str)
    log("info: " + str)
  end
  def notice(str)
    log("notice: " + str)
  end

  #
  def nullcmd()
  end
  private :nullcmd

  alias setmask nullcmd
  alias open!   reopen

end

# m = MultiLog.new

# m.open()
# m.log("ok")
# m.close
# print("ok\n")

# m.open($stderr)
# m.log("ok")
# m.close
# print("ok\n")

# fd = open("/tmp/mltest", "w")
# m.open(fd)
# m.log("ok")
# m.close
# fd.close

# open("/tmp/mltest2", "w") {
#   |fd|
#   m.open(fd)
#   m.log("ok")
#   m.close
# }

# require "socket"
# s = TCPSocket.new("localhost", 80)
# m.open(s)
# m.log("ok")
# m.close
# s.close

# end
