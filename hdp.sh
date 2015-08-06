#!/bin/bash

#-------------------------------------------------------------------------------------------------------
# Description: 
#    This is main script for provisioning RHEL 7.1 EC2 cluster for HDP 2.3.
#    Please refer to README.md for instructions on how to setup and use this script. 
#    
# Prerequisite:
#	 - AWS user is setup
#    - AWS access and secret keys are generated
#    - AWS user's keypair is setup and PEM file is generated
#    - Ansible control machine is setup and this git repo is copied there 
# 	 - AWS user's PEM file is copied to ansible user's home directory on Ansible control machine and permission is set to 400
#    - A default cluster configuration file exist in config folder or a new one is created.
#    
# Author: 
#   Tanveer Sattar (tanveersattar@yahoo.com)
#-------------------------------------------------------------------------------------------------------

var_config_dir="config"
var_inventory_path="$HOME/.ansible/local_inventory"

function usage(){
	echo "Usage: $0 <action> <config>"
	echo "     : action = setup|start|stop|terminate"
	echo "     : config = configuration file name from config directory"
}

function getawskeys(){
	echo -n "Please enter AWS access key and press [ENTER]: "
	read AWS_ACCESS_KEY
	echo -n "Please enter AWS secret key and press [ENTER]: "
	read AWS_SECRET_KEY
	
	if [ "$AWS_ACCESS_KEY" == "" -o "$AWS_SECRET_KEY" == "" ]; then
		echo "[ERROR] AWS access and secret keys are required" && exit 1
	else
		export AWS_ACCESS_KEY=$AWS_ACCESS_KEY
		export AWS_SECRET_KEY=$AWS_SECRET_KEY
	fi
}

if [ "$#" != "2" ]; then
	usage && exit 1
fi

if [ "$1" != "" -a "$1" != "setup" -a "$1" != "postsetup" -a "$1" != "start" -a "$1" != "stop" -a "$1" != "terminate" ]; then
	usage && exit 1
fi

var_conf_file="$var_config_dir/$2.conf"
if [ "$2" != "" -a ! -f $var_conf_file ]; then
	echo "[ERROR] Cluster configuration file $var_conf_file not found. Please make sure if correct cluster id is being used."
	usage && exit 1
fi

source $var_conf_file

var_inventory_dir="$var_inventory_path/$HDP_CLUSTER_ID"
if [ "$1" == "setup" -a -d $var_inventory_dir ]; then
	echo "[ERROR] Ansible local inventory $var_inventory_dir found. A cluster with same id might already be running."
	exit 1
fi 

if [ "$1" != "setup" -a ! -d $var_inventory_dir ]; then
	echo "[ERROR] Ansible local inventory $var_inventory_dir not found. Please make sure if correct cluster id is being used."
	exit 1
fi 

echo "----------------------------------------------------------------------------------------------"
echo "******     HDP Cluster Configuration     *****************************************************"
echo "----------------------------------------------------------------------------------------------"
echo "                   Cluster ID : $HDP_CLUSTER_ID"
echo "                 Cluster Name : $HDP_CLUSTER_NAME"
echo "             AWS Keypair Name : $AWS_KEYPAIR_NAME"
echo "                   AWS Region : $AWS_REGION"
echo "        AWS Availability Zone : $AWS_AVAILABILITY_ZONE"
echo "                 AWS Image ID : $AWS_IMAGE_ID"
echo "     Edge Node Instance Count : $HDP_EDGENODE_NUM"
echo "        Edge Node Hue Host ID : $HDP_EDGENODE_HUE_HOST_ID"
echo "     Edge Node Ambari Host ID : $HDP_EDGENODE_AMBARI_HOST_ID"
echo "      Edge Node Instance Type : $HDP_EDGENODE_INSTANCE_TYPE"
echo "  Edge Node Instance Vol (GB) : $HDP_EDGENODE_EBS_VOL_SIZE_GB"
echo "   Master Node Instance Count : $HDP_MASTERNODE_NUM"
echo "    Master Node Instance Type : $HDP_MASTERNODE_INSTANCE_TYPE" 
echo "Master Node Instance Vol (GB) : $HDP_MASTERNODE_EBS_VOL_SIZE_GB" 
echo "    Slave Node Instance Count : $HDP_SLAVENODE_NUM"
echo "     Slave Node Instance Type : $HDP_SLAVENODE_INSTANCE_TYPE"
echo " Slave Node Instance Vol (GB) : $HDP_SLAVENODE_EBS_VOL_SIZE_GB"
echo "                  JDK Version : $HDP_ORACLE_JDK_VER"
echo "             JDK Download URL : $HDP_ORACLE_JDK_DOWNLOAD_URL"
echo "        Ambari Repository URL : $HDP_AMBARI_REPO"
echo "     HDP Stack Repository URL : $HDP_REPO"
echo "    Ansible Host Key Checking : $ANSIBLE_HOST_KEY_CHECKING" 
echo "----------------------------------------------------------------------------------------------"

# export params as environment variables
export HDP_CLUSTER_ID=$HDP_CLUSTER_ID
export HDP_CLUSTER_NAME=$HDP_CLUSTER_NAME
export AWS_KEYPAIR_NAME=$AWS_KEYPAIR_NAME
export AWS_REGION=$AWS_REGION
export AWS_AVAILABILITY_ZONE=$AWS_AVAILABILITY_ZONE
export AWS_IMAGE_ID=$AWS_IMAGE_ID
export HDP_EDGENODE_NUM=$HDP_EDGENODE_NUM
export HDP_EDGENODE_HUE_HOST_ID=$HDP_EDGENODE_HUE_HOST_ID
export HDP_EDGENODE_AMBARI_HOST_ID=$HDP_EDGENODE_AMBARI_HOST_ID
export HDP_EDGENODE_INSTANCE_TYPE=$HDP_EDGENODE_INSTANCE_TYPE
export HDP_EDGENODE_EBS_VOL_SIZE_GB=$HDP_EDGENODE_EBS_VOL_SIZE_GB
export HDP_MASTERNODE_NUM=$HDP_MASTERNODE_NUM
export HDP_MASTERNODE_INSTANCE_TYPE=$HDP_MASTERNODE_INSTANCE_TYPE
export HDP_MASTERNODE_EBS_VOL_SIZE_GB=$HDP_MASTERNODE_EBS_VOL_SIZE_GB
export HDP_SLAVENODE_NUM=$HDP_SLAVENODE_NUM
export HDP_SLAVENODE_INSTANCE_TYPE=$HDP_SLAVENODE_INSTANCE_TYPE
export HDP_SLAVENODE_EBS_VOL_SIZE_GB=$HDP_SLAVENODE_EBS_VOL_SIZE_GB
export HDP_ORACLE_JDK_VER=$HDP_ORACLE_JDK_VER
export HDP_ORACLE_JDK_DOWNLOAD_URL=$HDP_ORACLE_JDK_DOWNLOAD_URL
export HDP_AMBARI_REPO=$HDP_AMBARI_REPO
export HDP_REPO=$HDP_REPO
export ANSIBLE_HOST_KEY_CHECKING=$ANSIBLE_HOST_KEY_CHECKING

# perform action on cluster
if [ "$1" = "setup" ]; then
	getawskeys 
	ansible-playbook -vvv ./ansible/setup.yml
	var_ambari_hostname=`awk '/internalhostname=/{print $NF}' $var_inventory_dir/edge.instances |grep edge$HDP_EDGENODE_AMBARI_HOST_ID | cut -d'=' -f 2`
	ansible-playbook -vv -i $var_inventory_dir/all.instances --extra-vars "ambarihost=$var_ambari_hostname" ./ansible/setup-common.yml
	ansible-playbook -vv -i $var_inventory_dir/edge.ambari.instances ./ansible/setup-edgenode-ambari.yml
elif [ "$1" = "postsetup" ]; then
	getawskeys
	ansible-playbook -vv -i $var_inventory_dir/all.instances ./ansible/post-setup-common.yml
	var_hue_hostname=`awk '/internalhostname=/{print $NF}' $var_inventory_dir/edge.instances |grep edge$HDP_EDGENODE_HUE_HOST_ID | cut -d'=' -f 2`
	#ansible-playbook -vv -i $var_inventory_dir/edge.hue.instances --extra-vars "huehost=$var_hue_hostname"  ./ansible/post-setup-edgenode-hue.yml	
elif [ "$1" = "start" ]; then
	getawskeys
	ansible-playbook -vv  ./ansible/start.yml
	ansible-playbook -vv -i $var_inventory_dir/all.instances ./ansible/start-common.yml
	ansible-playbook -vv -i $var_inventory_dir/edge.ambari.instances ./ansible/start-edgenode-ambari.yml
	#ansible-playbook -vv -i $var_inventory_dir/edge.hue.instances ./ansible/start-edgenode-hue.yml
elif [ "$1" = "stop" ]; then
	echo "You might want to stop all Hadoop services first, that can be done via Ambari."
	read -p "Do you want to stop cluster '$HDP_CLUSTER_ID' [y/N]? " -n 1 -r   
	echo
	if [[ $REPLY =~ ^[Yy]$ ]];then
		getawskeys
		ansible-playbook -vv ./ansible/stop.yml
	fi
elif [ "$1" = "terminate" ]; then
	read -p "Do you want to terminate cluster '$HDP_CLUSTER_ID' [y/N]? " -n 1 -r   
	echo
	if [[ $REPLY =~ ^[Yy]$ ]];then
		getawskeys
		ansible-playbook -vv ./ansible/terminate.yml
		
		if [ -d $var_inventory_dir ]; then 
			rm -rf $var_inventory_dir
		fi
	fi
else
	echo "[ERROR] Invalid action."
fi
