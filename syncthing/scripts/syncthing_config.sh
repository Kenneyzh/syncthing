#!/bin/sh
#2017/05/05 by kenney
#version 0.1

export KSROOT=/jffs/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export syncthing_`
conf_Path="$KSROOT/syncthing/config"

create_conf(){
    if [ ! -d $conf_Path ];then
        $KSROOT/syncthing/syncthing -generate=$conf_Path >>/tmp/syncthing.log
    fi
}
lan_ip=`nvram get lan_ipaddr`
weburl="http://$lan_ip:$syncthing_port"
get_ipaddr(){
    if [ $syncthing_wan_enable == 1 ];then
        ipaddr="0.0.0.0:$syncthing_port"
    else
        ipaddr="$lan_ip:$syncthing_port"
    fi
    sed -i "s/<address>[0-9.]\{7,15\}:[0-9]\{2,5\}<\/address>/<address>$ipaddr<\/address>/g" $conf_Path/config.xml
}
start_syncthing(){
    $KSROOT/syncthing/syncthing -home $conf_Path >>/tmp/syncthing.log &
    sleep 10
    #cru d syncthing
    #cru a syncthing "*/10 * * * * sh $KSROOT/scripts/syncthing_config.sh"
    dbus set syncthing_webui=$weburl
    if [ -L "$KSROOT/init.d/S94syncthing.sh" ];then 
        rm -rf $KSROOT/init.d/S94syncthing.sh
    fi
    ln -sf $KSROOT/scripts/syncthing_config.sh $KSROOT/init.d/S94syncthing.sh
}
stop_syncthing(){
    for i in `ps |grep syncthing|grep -v grep|grep -v "/bin/sh"|awk -F' ' '{print $1}'`;do
        kill $i
    done
    sleep 2
    #cru d syncthing
    if [ -L "$KSROOT/init.d/S94syncthing.sh" ];then 
        rm -rf $KSROOT/init.d/S94syncthing.sh
    fi
    dbus set syncthing_webui="--"
}

case $ACTION in
start)
	if [ "$syncthing_enable" = "1" ]; then
        create_conf
        get_ipaddr
        start_syncthing
	fi
	;;
stop)
	stop_syncthing
	;;
*)
    if [ "$syncthing_enable" = "1" ]; then
        if [ "`ps|grep syncthing|grep -v "/bin/sh"|grep -v grep|wc -l`" != "0" ];then 
            stop_syncthing
        fi
        create_conf
        get_ipaddr
        start_syncthing
	else
        stop_syncthing
    fi
    http_response '设置已保存！切勿重复提交！页面将在3秒后刷新'
	;;
esac
