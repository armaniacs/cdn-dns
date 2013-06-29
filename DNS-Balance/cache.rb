#
# キャッシュデータ管理
#

# $Id: cache.rb,v 1.3 2003/01/31 21:50:34 elca Exp $

# キャッシュの大きさ制限
# キャッシュは "timeout" の要素を持っている事
def cache_reduction(cache, overflow_size, logstr)
  h = Hash.new
  cache.each_key {
    |key|
    h[cache[key]["timeout"]] = key
  }
  if h.size > overflow_size
    del_h = h.keys.sort[0, h.size - overflow_size] # 古い順に並べる
    del_h.each { |i|
      ML.log(logstr + h[i].dump + "=>" + cache[key].to_s.dump)
      cache.delete(h[i])
    }
  end
end

# キャッシュの時間制限
# キャッシュは "timeout" の要素を持っている事
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
