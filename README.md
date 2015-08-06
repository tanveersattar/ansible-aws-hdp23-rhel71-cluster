# ansible-aws-hdp23-rhel71-cluster

Ansible playbooks to deploy Hortonworks Data Platform 2.3 cluster on RHEL 7.1 instances in AWS EC2.

<b>Features:</b>
 - Provision of RHEL 7.1 instances for a cluster
 - Deploy multiple clusters based on configuration files
 - Manage (start, stop and terminate) those clusters
 - Configure HDP 2.3 repositories 
 - Configure required packages and settings (JDK, SSH, Hostnames, IPTables, NTP, SELinux) 
 - Setup Amabri 2.1
 
<b>Note:</b> Ambari is setup by these scripts but HDP needs to be configured manually through Ambari UI. Work is in progress to integrate Ambari Blueprints to automate this process but not available yet.
 
<b>Work In Progress:</b>
 - Automated HDP cluster deployment using Ambari Blueprints
 - Automated Hue Installation
 
<b>Known Issues:</b> 
 - A bug in Ansible causes a task to skip if with_seuqence is used with count=1, this is fixed in 1.9.3 which is not released yet. https://github.com/ansible/ansible/issues/11422 </br> What does that mean here is that minimum number of instances for (edge, master or slaves) can be 2, and can not have single instance of any of this type, until Ansible 1.9.3 is released and upgraded on Ansible control machine where this is running. 
 

<b>Prerequisites:</b>
 - A valid AWS account
 - A valid AWS IAM (Identity and Access Management) user with 
	- admin access to launch and manage ec2 instances
	- access key and secret key generated
	- SSH key pair (.pem file)
 - A local or AWS Linux instance with Ansible installed (aka Ansible Control Machine) 
	
<b>Note:</b> One ec2-user and it's keys can be used for all clusters but you may want to create one user per cluster with
it's own set of keys (access, key, secret key, ssh key pair) to be used for security purpose.

<br><br>
<b>Quick Guide:</b>
 - Clone this repository to the Ansible Control Machine
 - Copy AWS user's PEM file in Ansible user's home directory and set permission to 400
 - Setup cluster nodes using commands: 
 	- <code>./hdp.sh setup hdp1</code>
 	- <code>./hdp.sh postsetup hdp1</code>
 - Ambari is setup on one of the edge nodes after post-setup, follow these instructions to setup HDP 2.3 using Ambari:
	<url>http://docs.hortonworks.com/HDPDocuments/Ambari-2.1.0.0/bk_Installing_HDP_AMB/content/index.html</url>
 - To stop cluster run:
 	- <code>./hdp.sh stop hdp1</code>
 	- may need to stop Hadoop services using Ambari before stopping cluster
 - To start cluster, run: 
 	- <code>./hdp.sh start hdp1</code>
 - To terminate cluster, run: 
 	- <code>./hdp.sh terminate hdp1</code>

<b>Note:</b> The parameter 'hdp1' is name of the configuration supplied in /config/hdp1.conf file. It will create a cluster with following configuration (please refer to detailed guide for more information on how to modify this configuration):
 - 2 Edge Nodes (with Ambari installed on first one, can be used to install client services) 
 - 2 Master Nodes (can be used for Hadoop master services and to configure Namenode High Availability)
 - 3 Slave Nodes (can be used as data nodes)


<br><br>
<b>Detailed Guide:</b>
 - Create an AWS account
 - Create a new IAM user with admin rights to manage ec2 instances
 - Create a set of access and secret keys for that user
 - Create a new key pair and download the PEM file
 - Setup Ansible on Linux instance (either local or in ec2) 
 - Ansible installation instruction are available at: http://docs.ansible.com/ansible/intro_installation.html 
 - Ansible installation steps for RHEL 7.1 in EC2 are:
	- setup basics
		- <code> sudo yum update -y </code>
		- <code> sudo yum install wget </code>
	
	- configure EPEL
		- <code> wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm </code>
		- <code> sudo rpm -ivh epel-release-7-5.noarch.rpm </code>
	
	- configure extra and optional RHEL repos
		- <code> sudo yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional </code>
	
	- install boto
		- <code> sudo yum install python-boto </code>
	
	- install ansible
		- <code> sudo yum install ansible </code>

 - Clone this repository to the Ansible Control Machine
 - Copy AWS user's PEM file in Ansible user's home directory and set permission to 400
 
 - A default configuration file hdp1.conf is already in config folder that can be used. It will create a cluster with following configuration:
	- 2 Edge Nodes (with Ambari installed on first one, can be used to install client services) 
	- 2 Master Nodes (can be used for Hadoop master services and to configure Namenode High Availability)
	- 3 Slave Nodes (can be used as data nodes)
 
 - Modifying Cluster Configuration:
	- If changes are required, make modification to hdp1.conf or make a copy then change variables in it  
	- While making changes make sure the name of conf file should be of format <code> \<clusterid\>.conf </code> where <code>\<clusterid\></code> is value of <code>HDP_CLUSTER_ID</code> in that configuration file. e.g. if <code>HDP_CLUSTER_ID="hdp23"</code> then config file name should be <code>hdp23.conf</code> 
	- There is no need to change anything in <code>variables.yml</code> file unless AWS VPC CIDR changes are required. All other config params are supplied via .conf files

 - Setting-up Multiple Clusters:
	- If more than one cluster are to be setup, create multiple AWS users and their credentials and create multiple configuration files and pass HDP_CLUSTER_ID in the configuration file to hdp shell script as described below.
 
 - Setup cluster nodes using commands: 
 	- <code> ./hdp.sh setup \<configname\>  </code>
 	- <code> ./hdp.sh postsetup \<configname\>  </code>
 - After post-setup is complete, follow these instructions to setup HDP 2.3 using Ambari:
	http://docs.hortonworks.com/HDPDocuments/Ambari-2.1.0.0/bk_Installing_HDP_AMB/content/index.html
	- At step "Select Stack": choose <code>HDP 2.3</code> and in "Advanced Repository Options" select only <code>redhat7</code>
	- At step "Install Options": in "Target Hosts" field input all hostnames from <code>~/.ansible/local_inventory/\<clusterid\>/hdp.hosts </code> (except localhost)
	- At step "Install Options": in "Hosts Registration Information" choose PEM file downloaded from AWS
	- At step "Install Options": in "SHH User Account" field input <code>ec2-user</code>
 - To stop cluster, run:
 	- <code> ./hdp.sh stop \<configname\> </code>
 	- may need stop Hadoop services using Ambari before stopping cluster
 - To start cluster, run: 
 	- <code> ./hdp.sh start \<configname\> </code>
 - To terminate cluster, run: 
 	- <code> ./hdp.sh terminate \<configname\> </code>
 
