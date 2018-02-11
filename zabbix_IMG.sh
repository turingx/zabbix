#!/bin/bash
 #此脚本功能为根据itemID获取其24小时内的图像
 
ZBX_URL="http://10.0.30.19"

#zabbix的账号密码 
USERNAME="admin"
PASSWORD="admin999！"
#数据监控的ITEMID分别为CPU，内存，硬盘，网络，进程5分钟负载
#此处监控两台服务器的5个参数，使用列表的形式存储
ITEMID_ARRY=(33296 33876 33398 34147 33294 34365 34382 34432 34405 34363)
ITEMID=""
#STIME=""
#图像获取的时间段的长度86400即24小时
PERIOD=86400
#图像宽度
WIDTH=800
#定义相关路径
GRAPH_DIR="/tmp/graph"
COOKIE="/tmp/zabbix_cookie"
CURL="/usr/bin/curl"
INDEX_URL="$ZBX_URL/index.php"
CHART_URL="$ZBX_URL/chart.php"
TMP=$(pwd)
#python脚本的路径
PY_DIR="$TMP/mail.py"

#zabbix账号密码认证，并生成cookie文件
function log_in(){

	if [ ! -s "$COOKIE" ];then
	    # 如果cookie文件不存在或者为空，则重新登录zabbix，并保存cookie文件
		   ${CURL} -c ${COOKIE} -d "name=${USERNAME}&password=${PASSWORD}&autologin=1&enter=Sign+in" $INDEX_URL | egrep -o "(Login name or password is incorrect|Account is blocked.*seconds)"
		   # 如果登录失败则退出脚本，并清空cookie文件i
		
		[ $? -eq 0 ] && { :>"$COOKIE"; exit 1;}
	fi
}


function get_zabbix_graph(){ 
		#从列表取出itemid，并给相应的id指定相应的名称
	for ITEMID in ${ITEMID_ARRY[@]}
	do
		if [ 33296 -eq $ITEMID ]
		then
			ITEM_NAME="Server1_CPU"
		elif [ 33876 -eq $ITEMID ]
		then 
			ITEM_NAME="Server1_MEM"
		elif [ 33398 -eq $ITEMID ]
		then 
			ITEM_NAME="Server1_DISK"
		elif [ 34147 -eq $ITEMID ]
		then 
			ITEM_NAME="Server1_NETWORK"
		elif [ 33294 -eq $ITEMID ]
		then 
			ITEM_NAME="Server1_LoadAvg"
		elif [ 34365 -eq $ITEMID ]
		then
			ITEM_NAME="Server2_CPU"
		elif [ 34382 -eq $ITEMID ]
		then 
			ITEM_NAME="Server2_MEM"
		elif [ 34432 -eq $ITEMID ]
		then 
			ITEM_NAME="Server2_DISK"
		elif [ 34405  -eq $ITEMID ]
		then 
			ITEM_NAME="Server2_NETWORK"
		elif [ 34363 -eq $ITEMID ]
		then 
			ITEM_NAME="Server2_LoadAvg"
		else
			echo ""
		fi
		#向zabbix服务器传递参数
		zbx_sessionid=$(grep 'zbx_sessionid' ${COOKIE} | awk '{printf $NF}')
		post_item_get=$(curl -X POST -H 'Content-Type: application/json-rpc' -d "
		{
		    \"jsonrpc\": \"2.0\",
		    \"method\": \"item.get\",
		    \"params\": {
			\"output\": \"extend\",
			\"itemids\": \"$ITEMID\",
			\"filter\": {
			    \"value_type\": [
			    \"0\",\"3\"
			    ]
			}
		    },
		    \"auth\": \"$zbx_sessionid\",
		    \"id\": 1
		}" ${ZBX_URL}/api_jsonrpc.php 2>/dev/null)
		#获取post_item_get里面值得类型
		if_numeric=$(echo "$post_item_get" | grep 'value_type')
		[ -z "$if_numeric" ] && { echo "The value of the item is not a valid numeric value."; exit 1;}

		[ -d "$GRAPH_DIR" ] || mkdir -p "$GRAPH_DIR"
		#PNG_PATH="$GRAPH_DIR/$ITEMID.$PERIOD.${WIDTH}.png"
		PNG_PATH="$GRAPH_DIR/$ITEM_NAME.png"
		#获取图像
		(${CURL} -b ${COOKIE} -d "itemids%5B0%5D=${ITEMID}&period=${PERIOD}&width=${WIDTH}" $CHART_URL > "$PNG_PATH")&>/dev/null
		#[ -s "$PNG_PATH" ] && echo "Saved the graph as $PNG_PATH" || echo "Failed to get the graph."
		#echo "If the graph is not correct, please check variables or clean $COOKIE file."
		#echo "$count"
	done 
}

log_in
get_zabbix_graph

#调用python脚本
$PY_DIR
