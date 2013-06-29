#! /bin/bash
#
# ���������� RingServer �� addr �ե��������³����
# ���κݹ�������Υ���Ĥ�

N=$$
h=999

while true
do
    #echo -n "update:"

    next_h=`date '+%S'`
    now=`date '+%s'`

    perl get_httpd_stat > out.db-${now}
    cat out.db-${now} | sort | uniq | ruby makedb.rb > addr.tmp.${N}

    # 1���֤�1�������
    if [ $h != $next_h ]
    then
	cp -p out.db-${now} out/
	gzip -9 out/out.db-${now}
    fi

    h=$next_h

    mv addr.tmp.${N} addr
    rm out.db-${now}

    sleep 300
done

# end
