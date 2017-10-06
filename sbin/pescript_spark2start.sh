#!/bin/bash

# Parallel Environment (PE) script for integration with Univa Grid Engine.
# (May work with other versions of Grid Engine.)
#
# Example PE:
#
# pe_name                spark2
# slots                  99999
# used_slots             0
# bound_slots            0
# user_lists             NONE
# xuser_lists            NONE
# start_proc_args        /opt/sge/var/default/common/pescripts/spark2start.sh
# stop_proc_args         NONE
# allocation_rule        16
# control_slaves         FALSE
# job_is_first_task      FALSE
# urgency_slots          min
# accounting_summary     FALSE
# daemon_forks_slaves    FALSE
# master_forks_slaves    TRUE

spark_conf_dir=${SGE_O_WORKDIR}/conf.${JOB_ID}
/bin/mkdir -p ${spark_conf_dir}

### XXX
### To update for your installation
### * spark_home    -- Spark installation prefix
### * java_version  -- JRE installation prefix
### * the "export PATH" and "setenv PATH" lines below; 
###     this pescript assumes a private installation of Intel Distribution for Python
###     in prefix $SPARK_HOME/intelpython3


spark_home="/mnt/HA/opt/apache/spark/2.2.0"

java_version="java-1.8.0-oracle.x86_64"


###
### for bash-like
###
sparkenvfile=${spark_conf_dir}/spark-env.sh

echo "#!/usr/bin/env bash" > $sparkenvfile
echo "export JAVA_HOME=/usr/lib/jvm/${java_version}" >> $sparkenvfile
echo "export PATH=${spark_home}/bin:${spark_home}/sbin:${spark_home}/intelpython3/bin:${PATH}" >> $sparkenvfile
echo "export SPARK_CONF_DIR=${spark_conf_dir}" >> $sparkenvfile
echo "export SPARK_MASTER_WEBUI_PORT=8880" >> $sparkenvfile
echo "export SPARK_WORKER_WEBUI_PORT=8881" >> $sparkenvfile
echo "export SPARK_WORKER_INSTANCES=1" >> $sparkenvfile

spark_master_host=$( cat ${PE_HOSTFILE} | head -1 | cut -f1 -d\  )
echo "export SPARK_MASTER_HOST=${spark_master_host}" >> $sparkenvfile

spark_master_port=7077
echo "export SPARK_MASTER_PORT=${spark_master_port}" >> $sparkenvfile
echo "export SPARK_MASTER_URL=spark://${spark_master_host}:${spark_master_port}" >> $sparkenvfile

spark_slaves=${SGE_O_WORKDIR}/slaves.${JOB_ID}
echo "export SPARK_SLAVES=${spark_slaves}" >> $sparkenvfile

spark_worker_cores=$( expr ${NSLOTS} / ${NHOSTS} )
echo "export SPARK_WORKER_CORES=${spark_worker_cores}" >> $sparkenvfile

spark_worker_dir=/lustre/scratch/${SGE_O_LOGNAME}/spark/work.${JOB_ID}
echo "export SPARK_WORKER_DIR=${spark_worker_dir}" >> $sparkenvfile

spark_log_dir=${SGE_O_WORKDIR}/logs.${JOB_ID}
echo "export SPARK_LOG_DIR=${spark_log_dir}" >> $sparkenvfile
echo "export SPARK_WORKER_LOG_DIR=${spark_log_dir}" >> $sparkenvfile

echo "export SPARK_LOCAL_DIRS=${TMP}" >> $sparkenvfile

chmod +x $sparkenvfile


###
### for csh-like
###
sparkenvfile=${spark_conf_dir}/spark-env.csh

echo "#!/usr/bin/env tcsh" > $sparkenvfile
echo "setenv JAVA_HOME /usr/lib/jvm/${java_version}" >> $sparkenvfile
echo "setenv PATH ${spark_home}/bin:${spark_home}/sbin:${spark_home}/intelpython3/bin:${PATH}" >> $sparkenvfile
echo "setenv SPARK_CONF_DIR ${spark_conf_dir}" >> $sparkenvfile
echo "setenv SPARK_MASTER_WEBUI_PORT 8880" >> $sparkenvfile
echo "setenv SPARK_WORKER_WEBUI_PORT 8881" >> $sparkenvfile
echo "setenv SPARK_WORKER_INSTANCES 1" >> $sparkenvfile

spark_master_host=$( cat ${PE_HOSTFILE} | head -1 | cut -f1 -d\  )
echo "setenv SPARK_MASTER_HOST ${spark_master_host}" >> $sparkenvfile

echo "setenv SPARK_MASTER_PORT 7077" >> $sparkenvfile
echo "setenv MASTER_URL spark://${spark_master_host}:7077" >> $sparkenvfile

spark_slaves=${SGE_O_WORKDIR}/slaves.${JOB_ID}
echo "setenv SPARK_SLAVES ${spark_slaves}" >> $sparkenvfile

spark_worker_cores=$( expr ${NSLOTS} / ${NHOSTS} )
echo "setenv SPARK_WORKER_CORES ${spark_worker_cores}" >> $sparkenvfile

spark_worker_dir=/lustre/scratch/${SGE_O_LOGNAME}/spark/work.${JOB_ID}
echo "setenv SPARK_WORKER_DIR ${spark_worker_dir}" >> $sparkenvfile

spark_log_dir=${SGE_O_WORKDIR}/logs.${JOB_ID}
echo "setenv SPARK_LOG_DIR ${spark_log_dir}" >> $sparkenvfile
echo "setenv SPARK_WORKER_LOG_DIR ${spark_log_dir}" >> $sparkenvfile

echo "setenv SPARK_LOCAL_DIRS ${TMP}" >> $sparkenvfile

chmod +x $sparkenvfile


/bin/mkdir -p ${spark_log_dir}
/bin/mkdir -p ${spark_worker_dir}
cat ${PE_HOSTFILE} | cut -f1 -d \  > ${spark_slaves}

### defaults, sp. log directory
echo "spark.eventLog.dir    ${spark_log_dir}" > ${spark_conf_dir}/spark-defaults.conf

### log4j defaults
log4j_props=${spark_conf_dir}/log4j.properties
echo "### Suggestion: use "WARN" or "ERROR"; use "INFO" when debugging" > $log4j_props
echo "# Set everything to be logged to the console" >> $log4j_props
echo "log4j.rootCategory=WARN, console" >> $log4j_props
echo "log4j.appender.console=org.apache.log4j.ConsoleAppender" >> $log4j_props
echo "log4j.appender.console.target=System.err" >> $log4j_props
echo "log4j.appender.console.layout=org.apache.log4j.PatternLayout" >> $log4j_props
echo "log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n" >> $log4j_props
echo "# Settings to quiet third party logs that are too verbose" >> $log4j_props
echo "log4j.logger.org.spark-project.jetty=WARN" >> $log4j_props
echo "log4j.logger.org.spark-project.jetty.util.component.AbstractLifeCycle=ERROR" >> $log4j_props
echo "log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper=INFO" >> $log4j_props
echo "log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter=INFO" >> $log4j_props

