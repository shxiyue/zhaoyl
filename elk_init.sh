#!/bin/bash 
#start or stop elk

_Help()
{
cat <<!

Usage
     elk_init.sh <product> <pro_status> <logstashfile>|<kibanaport>
exp
     sh elk_init.sh elasticsearch start

Parameters of the usage:
    product : elasticsearch|kibana|logstash
    pro_status : start|stop
    logstashfile : /home/zhaoyl/open_source/logstash-5.2.1/bin/logstash.conf (full path)
    kibanaport : default 5601

!

exit 21
}

_Echf()
{
    u_MsgType=$1
    u_Msg=$2
    u_MsgHead=""
    u_ResCode=255
    Time=`date "+%Y/%m/%d %H:%M:%S"`
    case ${u_MsgType} in
        M)  u_MsgHead="  [M]   [$Time]"
            u_ResCode=0
          ;;
        W)  u_MsgHead=" *[W]   [$Time]"
            u_ResCode=11
          ;;
        E)  u_MsgHead="**[Err] [$Time]"
            u_ResCode=255
          ;;
        SYS)u_MsgHead="**[SYS] [$Time]"
            u_ResCode=0
          ;;
        NH) u_MsgHead=""
            u_Msg="${u_Msg}    "
            u_ResCode=0
          ;;
        CLE)u_MsgHead=""
            >$LogPatch/$LogFileName
            u_ResCode=0
          ;;
        TIT)u_ShellRunTimes=0
            u_MsgHead=""
            u_ShellRunTimes=`grep 'ShellRunTimes:[0-9]' $LogPatch/$LogFileName 2>>/dev/null | awk -F ':' '{gsub("-","");print $2}'|wc -l `
            u_ShellRunTimes=`echo "${u_ShellRunTimes}+1" |bc `
            u_Msg="\n\n----------------------------------------------- ShellRunTimes:${u_ShellRunTimes} -----------------------------------------------"
            u_ResCode=0
          ;;
        *)  u_Msg="**[Err] [$Time]"
            u_Msg="Message type Input Error MsgType:[${u_MsgType}]"
            u_ResCode=21
          ;;
    esac
    echo -e "${u_Msg}" | while read u_Once
    do
    	  echo -e "${u_MsgHead}  ${u_Once}" | tee -a $LogPatch/$LogFileName
    done
    if [ $? -ne 0 ]
    then
        echo "The log file output failure"
        exit 254
    fi
    return ${u_ResCode}
}

#set env
BizDate=`date +%Y%m%d`
LogPatch={{desthomedir}}/logs
LogFileName="elk_init_${BizDate}.log" 
BasePath={{desthomedir}}
logstash_file=${LogPatch}/logstash.pid
elasticsearch_file=${LogPatch}/elasticsearch.pid
kibana_file=${LogPatch}/kibana.pid
kibana_log=${LogPatch}/kibana.log
JAVA_HOME=`echo $JAVA_HOME`
#check param
if [ $# -lt 2 ]
then
    echo "Number of parameters is not correct"
	  _Help
fi
#set param
product=$1
pro_status=$2
logstashfile=""
kibanaport=""


_Echf TIT

case $1 in 
    logstash)
      if [ "${pro_status}"X == "stop"X ]
      then sleep 0.5
      else if [ "${pro_status}"X == "start"X ] && [ -n "${3}" ] ;then 
           logstashfile=$3
           else _Help
           fi
      fi 
      ;;
    kibana)
      if [ "${pro_status}"X == "stop"X ]
      then sleep 0.5
      else if [ "${pro_status}"X == "start"X ] && [ -n "${3}" ] ;then 
           kibanaport=$3
           else _Help
           fi
      fi 
      ;; 
    elasticsearch)
      sleep 0.5
      ;;
    *)
      _Help
      ;;
esac   
 


if [ ${product} = "logstash" ] ; then
  case ${pro_status} in
      start)
        nohup sh ${BasePath}/opt/logstash-5.2.1/bin/logstash -f ${logstashfile} 1>/dev/null 2>&1 &
        sleep 3
        logstash_pid=`ps -ef |grep -i logstash |grep -v grep|grep -v $0|awk '{print $2}'`        
#        echo `ps -ef |grep -i logstash |grep -v grep|grep -v $0`
        if [ ! -z "${logstash_pid}" ] ; then 
            echo $logstash_pid>$logstash_file
            _Echf "M" "Start Logstash  successful PID:${logstash_pid}"
           else  _Echf "E" "Start Logstash fail,please check Logstash log :${BasePath}/opt/logstash-5.2.1/logs"
        fi
        ;;
      stop)
        cat ${logstash_file} |xargs kill
        if [ $? -le 1 ] ; then
           _Echf "M" "Stop Logstash  successful "
         else _Echf "E" "Stop Logstash fail,please check Logstash log :${BasePath}/opt/logstash-5.2.1/logs"
        fi
        ;;
      *)
        _Help
        exit 1
        ;;
  esac
  else if [ ${product} = "elasticsearch" ] ; then  
         case ${pro_status} in 
             start)
              nohup  ${BasePath}/opt/elasticsearch-5.2.1/bin/elasticsearch -d &
               sleep 10
               elasticsearch_pid=`jps | grep -i  elasticsearch | grep -v grep | awk '{print $1}'`
               if [ ! -z ${elasticsearch_pid} ] ; then 
                   echo $elasticsearch_pid>$elasticsearch_file
                   _Echf "M" "Start elasticsearch  successful PID:${elasticsearch_pid}"
                  else  _Echf "E" "Start elasticsearch fail,please check elasticsearch log :${BasePath}/opt/elasticsearch-5.2.1/logs"
               fi 
             ;;
             stop)
               cat ${elasticsearch_file} |xargs kill
               if [ $? -le 1 ] ; then
                  _Echf "M" "Stop elasticsearch  successful "
                else _Echf "E" "Stop elasticsearch fail,please check elasticsearch log :${BasePath}/opt/elasticsearch-5.2.1/logs"
               fi
             ;;
             *)
               _Help
               exit 2
             ;;
             esac
           else 
              case ${pro_status} in 
               start)
                  nohup sh ${BasePath}/opt/kibana-5.2.2/bin/kibana 1>${kibana_log} 2>&1  &  
                  sleep 3
                  fuser -n tcp ${kibanaport} 1>${kibana_file} 2>/dev/null
                  kibana_pid=`cat ${kibana_file} |sed 's/ //g'`
                  if [ ! -z ${kibana_pid} ] ; then
                    _Echf "M" "Start kibana  successful PID:${kibana_pid}"
                   else _Echf "E" "Start kibana fail,please check kibana log :${kibana_log}"
                  fi
                ;;
               stop)
                  cat ${kibana_file} |sed 's/ //g' |xargs kill
                   if [ $? -le 1 ] ; then
                      _Echf "M" "Stop kibana  successful "
                    else _Echf "E" "Stop kibana fail,please check kibana log :${kibana_log}"
                   fi  
                ;;
               *)
                 _Help
                 exit 3
                ;;
              esac
           fi
fi              
exit $?

