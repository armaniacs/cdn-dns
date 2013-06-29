#
# $B%-%c%C%7%e%G!<%?4IM}(B
#

# $Id: cache.rb,v 1.3 2003/01/31 21:50:34 elca Exp $

# $B%-%c%C%7%e$NBg$-$5@)8B(B
# $B%-%c%C%7%e$O(B "timeout" $B$NMWAG$r;}$C$F$$$k;v(B
def cache_reduction(cache, overflow_size, logstr)
  h = Hash.new
  cache.each_key {
    |key|
    h[cache[key]["timeout"]] = key
  }
  if h.size > overflow_size
    del_h = h.keys.sort[0, h.size - overflow_size] # $B8E$$=g$KJB$Y$k(B
    del_h.each { |i|
      ML.log(logstr + h[i].dump + "=>" + cache[key].to_s.dump)
      cache.delete(h[i])
    }
  end
end

# $B%-%c%C%7%e$N;~4V@)8B(B
# $B%-%c%C%7%e$O(B "timeout" $B$NMWAG$r;}$C$F$$$k;v(B
def cache_timeout(cache, logstr)
  cache.each_key {
    |key|
    if cache[key]["timeout"] < Time.now.to_i
      ML.log(logstr + key.dump + "=>" + cache[key].to_s.dump)
      cache.delete(key)
    end
  }
end

# end
