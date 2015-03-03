#!/usr/bin/env bash

if [ `whoami` == "root" ]; then
    echo "root is not allowed"
    exit 1
fi

if [ $(./bin/hdfs getconf -namenodes | awk '{print $1; print $2;}' | grep `hostname` | wc -l) -eq 0 ]; then
    echo "please run this script on one namenode machine"
    exit 1
fi

echo
echo "###########################################################"
echo "## WARNING: only run once just after hadoop be installed ##"
echo "###########################################################"
echo
read -p "Press any key to continue ... "


################################################################################
#
# init hadoop
#

# start journalnode
echo "> start journal node"
sleep 3
#read -p "Press any key to continue ... "
./journalnode.sh start
echo


echo "> wait 10 seconds for journal node initing ... "
sleep 10
echo

# format namenode
echo "> format name node"
sleep 3
#read -p "Press any key to continue ... "
./bin/hdfs namenode -format
echo


# start namenode
echo "> start namenode on this machine"
sleep 3
. admin_env.sh
$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_PREFIX/conf --script hdfs start namenode
# wait a moment
sleep 5


# start other namenode
echo "> start other namenode -bootstrapStandby"
sleep 3
other_master=$(./bin/hdfs getconf -namenodes | grep -v WARN | tail -1 | awk '{print $1; print $2;}' | grep -v `hostname`)
ssh $SSH_OPTS $other_master "cd $HADOOP_PREFIX; ./bin/hdfs namenode -bootstrapStandby"


# stop namenode
echo "> stop namenode on this machine"
sleep 3
$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_PREFIX/conf --script hdfs stop namenode


# format zookeeper
echo "> format zookeeper"
sleep 3
#read -p "Press any key to continue ... "
./bin/hdfs zkfc -formatZK
echo


# 
echo "> stop journal node"
sleep 3
#read -p "Press any key to continue ... "
./journalnode.sh stop
echo


echo "> format namenode over, you can start hadoop by run ./admin.sh"

