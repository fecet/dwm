#! /bin/bash

tempfile=$(cd $(dirname $0);cd ..;pwd)/temp

this=_wifi
icon_color="^c#000080^^b#a6e3a10xff^"
text_color="^c#000080^^b#a6e3a10xff^"
signal=$(echo "^s$this^" | sed 's/_//')

# check
[ ! "$(command -v nmcli)" ] && echo command not found: nmcli && exit

#是否第一次执行网速
is_first = false

# 中英文适配
wifi_grep_keyword="已连接 到"
wifi_disconnected="未连接"
wifi_disconnected_notify="未连接到网络"
if [ "$LANG" != "zh_CN.UTF-8" ]; then
    wifi_grep_keyword="connected to"
    wifi_disconnected="disconnected"
    wifi_disconnected_notify="disconnected"
fi

update() {
    wifi_icon=""
    is_net=$( cat $DWM/statusbar/netflag )
    if [[ $is_first == true ]];then
        wifi_text=" 0.00KB/s  0.00KB/s"
    elif [[ "$is_net" != "" ]];then
        # 获取网卡名
        DEVICE=$(ls /sys/class/net | grep ^w)
        if [[ ! -n $DEVICE ]]; then
            DEVICE=$(ls /sys/class/net | grep -v lo | head -1)
        fi
        wifi_text=$( sar -n DEV 1 1 | grep $DEVICE |grep -E "Average|平均时间" | awk 'BEGIN{a="";b="";c=" ";d="KB/s"}{print  a""c""$5""d""c""b""c""$6""d }' )
    else
        wifi_text=$(nmcli | grep "$wifi_grep_keyword" | awk -F "$wifi_grep_keyword" '{print $2}')
        [ "$wifi_text" = "" ] && wifi_text=$wifi_disconnected
    fi

    #避免切换之前已经有个线程在跑了
    is_net=$( cat $DWM/statusbar/netflag )
    is_show_net=$( echo $wifi_text| grep  )
    if [[ "$is_net" == "" && "$is_show_net" != "" ]]; then
        :
    else
        icon=" $wifi_icon"
        text="$wifi_text "
        sed -i '/^export '$this'=.*$/d' $tempfile
        printf "export %s='%s%s%s%s%s'\n" $this "$signal" "" "" "$text_color" "$icon $text" >> $tempfile
    fi
}

notify() {
    update
    notify-send "$wifi_icon  Wifi" "$wifi_text"
}

call_nm() {
    pid1=`ps aux | grep 'st -t statusutil' | grep -v grep | awk '{print $2}'`
    pid2=`ps aux | grep 'st -t statusutil_nm' | grep -v grep | awk '{print $2}'`
    mx=`xdotool getmouselocation --shell | grep X= | sed 's/X=//'`
    my=`xdotool getmouselocation --shell | grep Y= | sed 's/Y=//'`
    kill $pid1 && kill $pid2 || st -t statusutil_nm -g 60x25+$((mx - 240))+$((my + 20)) -c FGN -C "#222D31@4" -e 'nmtui-connect'
}

switch_mode() {
    is_net=$( cat $DWM/statusbar/netflag )
    if [ -n "$is_net" ];then
        echo "" >  $DWM/statusbar/netflag
    else
        echo "true" >  $DWM/statusbar/netflag
        is_first=true
    fi
}

click() {
    case "$1" in
        L) switch_mode ;update;;
        R) ~/.config/eww/System-Menu/scripts/networkmanager_dmenu  ;;
    esac
}

case "$1" in
    click) click $2 ;;
    notify) notify ;;
    *) update ;;
esac
