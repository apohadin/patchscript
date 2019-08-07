#!/bin/bash
# ------------------------------------------------------------
# Name  : rhel-patching.sh
# Desc  : Perform basic server patch tasks for RHEL servers
# Group : ETS Linux/Unix Patching
# Author: Neil Anthony Camara <NeilAnthony.Camara@fisglobal.com>
# History: 20190802 Initial draft
#
# Note  : Initially, this was port of rhel-patching.sh for RHEL5/6/7 servers.
#         However, it turns out that some of bash functionality in RHEL5/6/7
#         was bit wonky in older bash.
#
# TODO  : 1. Display of available UPDATES to have and going to be installed
#         2. Check Boks enable and disable daemon
#         3. Check Centos or RHEL and version
#         4. Check Satellite connection and register if has errors
#	  5. Output previous patch status
#         6. Check vmware tools is installed/not installed or is not a Vmware machine
# ------------------------------------------------------------

echo "Patch ...."
echo "executing ..."
echo ""

apache_stat() {
       echo "Checking Apache..."
       if [ "$(apachectl status)" = 0 ];then
         echo "Apache is enabled stopping now ..."
         apachectl stop
       else
         echo "Apache is stopped"

      fi
}

tomcat_stat() {
         echo "Checking Tomcat..."
         if [ "$(systemctl status tomcat.service)" = 0 ];then
         echo "Tomcat is enabled stopping now ..."
         systemctl stop tomcat.service
       else
         echo "Tomcat is stopped"

      fi
}


patch_last() {
       val="$(rpm -qa --last|head -n1|awk '{print $1=""; print $0}')"
       echo ${val}
       yum history
}

check_OSVER() {
       if [ "$(uname -s)" != 'Linux' -o ! -f /etc/redhat-release ]; then
        echo "This script only runs on RHEL servers."; exit 1
       elif [ "$(id -u)" != "0" ]; then
        echo "You need to run this script as root!"; exit 1
       else 
          OS=`cat /etc/redhat-release`
          echo "OS version is ${OS}"
       fi
}

check_SatSUB() {
      echo -e "\nChecking Red Hat Satellite Subscription .."
    if [ grep -i centos /etc/redhat-release -eq 1 ]; then
      if [ -f /sbin/subscription-manager ];then
         if [ `subscription-manager status|grep -i Current` -eq 0 ];then
           echo -e "\nSubscription is in current status"
           echo -e "\nProceeding to Patching steps"
         else
            if [ cat /etc/redhat-release |grep 6 -eq 0 ];then
              echo -e "\nRe-registering Subscription to Red Hat Satellite.."
             subscription-manager remove --all
             subscription-manager unregister
             subscription-manager refresh
             subscription-manager status
             curl http://10.56.8.29/pub/bootstrap.py | sudo python - --server='amo1rfissatsm01.cust.au' --location='MEL' --organization='FIS' --activationkey='rhel6' --skip-foreman --force"
             subscription-manager auto-attach
             subscription-manager attach
           else
             echo -e "\nRe-registering Subscription to Red Hat Satellite.."
             subscription-manager remove --all
             subscription-manager unregister
             subscription-manager refresh
             subscription-manager status
             curl http://10.56.8.29/pub/bootstrap.py | sudo python - --server='amo1rfissatsm01.cust.au' --location='MEL' --organization='FIS' --activationkey='rhel7' --skip-foreman --force"
             subscription-manager auto-attach
             subscription-manager attach
           fi
         fi  
       fi 
      echo "subscription-manager status"
 fi
}


boks_disable() {
         if [ -f /usr/boksm/lib/sysreplace ];then
         echo -e "\nDisable BoKs Authentication ...\n"
         /usr/boksm/lib/sysreplace restore
         else
           echo "This Server is not Boks managed"
         fi
}

patch_stat() {
         if [ -f /bin/yum ];then
         echo -e "Using yum utility to update server ...\n"
         yum update -y
         elif [ -f /usr/bin/yum ];then
             echo -e "Using yum utility to update server ...\n"
             yum update -y
         else 
            echo "This is not a Red Hat Machine"
         fi     
}

boks_enable() {
        if [ -f /usr/boksm/lib/sysreplace ];then
        echo -e "\nDisable BoKs Authentication ...\n"
        /usr/boksm/lib/sysreplace replace
        else
          echo "This Server is not Boks managed"
        fi
}

vmware_tools() {
        echo -e "\nChecking Vmware tools ..."
        if dmidecode | grep -i "VMware Virtual Platform" &> /dev/null; then
           echo -e "\nRunning as Guest OS ..."
           dmidecode|grep -i product
           echo -e "\nCalling 'vmware-config-tools.pl' utility ..."
          
          if [ -f /usr/bin/vmware-config-tools.pl ]; then
              /usr/bin/vmware-config-tools.pl
          else
             echo "WARNING!!! vmware tools is not installed!!"
          fi

        else
            echo -e "\nRunning on Physical server ..."
            dmidecode | grep -i product
         fi
}

apache_stat
tomcat_stat
check_OSVER
patch_last
boks_disable
patch_stat
boks_enable
vmware_tools
