#!/bin/bash
echo "Patch testing...."
echo "executing ..."
echo ""

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
             echo -e "\nRe-registering Subscription to Red Hat Satellite.."
             echo "subscription-manager remove --all"
             echo "subscription-manager unregister"
             echo "subscription-manager refresh"
             echo "subscription-manager status"
             echo "curl http://10.56.8.29/pub/bootstrap.py | sudo python - --server='amo1rfissatsm01.cust.au' --location='MEL' --organization='FIS' --activationkey='rhel7' --skip-foreman --force"
             echo "subscription-manager auto-attach"
             echo "subscription-manager attach"
         fi  
       fi 
      echo "Centos OS Please Check Repository"
 fi
}


boks_disable() {
         if [ -f /usr/boksm/lib/sysreplace ];then
         echo -e "\nDisable BoKs Authentication ...\n"
         echo "/usr/boksm/lib/sysreplace restore"
         else
           echo "This Server is not Boks managed"
         fi
}

patch_test() {
         if [ -f /bin/yum ];then
         echo -e "Using yum utility to update server ...\n"
         echo "yum update -y"
         elif [ -f /usr/bin/yum ];then
             echo -e "Using yum utility to update server ...\n"
              echo "yum update -y"
         else 
            echo "This is not a Red Hat Machine"
         fi     
}

boks_enable() {
        if [ -f /usr/boksm/lib/sysreplace ];then
        echo -e "\nDisable BoKs Authentication ...\n"
        echo "/usr/boksm/lib/sysreplace replace"
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
             echo " /usr/bin/vmware-config-tools.pl"
          else
             echo "WARNING!!! vmware tools is not installed!!"
          fi

        else
            echo -e "\nRunning on Physical server ..."
            dmidecode | grep -i product
         fi
}

check_OSVER
patch_last
boks_disable
patch_test
boks_enable
vmware_tools
