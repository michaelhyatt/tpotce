#!/bin/bash

# Some global vars
myCONFIGFILE="/opt/tpot/etc/tpot.yml"
myCOMPOSEPATH="/opt/tpot/etc/compose"
myRED="[0;31m"
myGREEN="[0;32m"
myWHITE="[0;0m"
myBLUE="[0;34m"


# Check for existing tpot.yml
function fuCONFIGCHECK () {
  echo "### Checking for T-Pot configuration file ..."
  echo -n "###### $myBLUE$myCONFIGFILE$myWHITE "
  if ! [ -f $myCONFIGFILE ];
    then
      echo
      echo "[ $myRED""NOT OK""$myWHITE ] - No T-Pot configuration found."
      echo "Please create a link to your desired config i.e. 'ln -s /opt/tpot/etc/compose/standard.yml /opt/tpot/etc/tpot.yml'."
      echo
      exit 1
    else
      echo "[ $myGREEN""OK""$myWHITE ]"
  fi
echo
}

# Let's test the internet connection
function fuCHECKINET () {
mySITES=$1
  echo "### Now checking availability of ..."
  for i in $mySITES;
    do
      echo -n "###### $myBLUE$i$myWHITE "
      curl --connect-timeout 5 -IsS $i 2>&1>/dev/null
        if [ $? -ne 0 ];
          then
	    echo
            echo "###### $myBLUE""Error - Internet connection test failed.""$myWHITE"" [ $myRED""NOT OK""$myWHITE ]"
            echo "Exiting.""$myWHITE"
            echo
            exit 1
          else
            echo "[ $myGREEN"OK"$myWHITE ]"
        fi
  done;
echo
}

# Update
function fuSELFUPDATE () {
  echo "### Now checking for newer files in repository ..."
  git fetch --all
  myREMOTESTAT=$(git status | grep -c "up-to-date")
  if [ "$myREMOTESTAT" != "0" ];
    then
      echo "###### $myBLUE""No updates found in repository.""$myWHITE"
      return
  fi
  myRESULT=$(git diff --name-only origin/18.04 | grep update.sh)
  if [ "$myRESULT" == "update.sh" ];
    then
      echo "###### $myBLUE""Found newer version, will be pulling updates and restart myself.""$myWHITE"
      git reset --hard
      git pull --force
      exec "$1" "$2"
      exit 1
    else
      echo "###### $myBLUE""Pulling updates from repository.""$myWHITE"
      git reset --hard
      git pull --force
  fi
echo
}

# Let's check for version
function fuCHECK_VERSION () {
local myMINVERSION="18.04.0"
local myMASTERVERSION="18.10.0"
echo
echo "### Checking for version tag ..."
if [ -f "version" ];
  then
    myVERSION=$(cat version)
    if [[ "$myVERSION" > "$myMINVERSION" || "$myVERSION" == "$myMINVERSION" ]] && [[ "$myVERSION" < "$myMASTERVERSION" || "$myVERSION" == "$myMASTERVERSION" ]]
      then
        echo "###### $myBLUE$myVERSION is eligible for the update procedure.$myWHITE"" [ $myGREEN""OK""$myWHITE ]"
      else
        echo "###### $myBLUE $myVERSION cannot be upgraded automatically. Please run a fresh install.$myWHITE"" [ $myRED""NOT OK""$myWHITE ]"
	exit
    fi
  else
    echo "###### $myBLUE""Unable to determine version. Please run 'update.sh' from within '/opt/tpot'.""$myWHITE"" [ $myRED""NOT OK""$myWHITE ]"
    exit
  fi
echo
}


# Stop T-Pot to avoid race conditions with running containers with regard to the current T-Pot config
function fuSTOP_TPOT () {
echo "### Need to stop T-Pot ..."
echo -n "###### $myBLUE Now stopping T-Pot.$myWHITE "
systemctl stop tpot
if [ $? -ne 0 ];
  then
    echo " [ $myRED""NOT OK""$myWHITE ]"
    echo "###### $myBLUE""Could not stop T-Pot.""$myWHITE"" [ $myRED""NOT OK""$myWHITE ]"
    echo "Exiting.""$myWHITE"
    echo
    exit 1
  else
    echo "[ $myGREEN"OK"$myWHITE ]"
    echo "###### $myBLUE Now cleaning up containers.$myWHITE "
    if [ "$(docker ps -aq)" != "" ];
      then
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)
    fi
fi
echo
}

# Backup
function fuBACKUP () {
local myARCHIVE="/root/$(date +%Y%m%d%H%M)_tpot_backup.tgz"
local myPATH=$PWD
echo "### Create a backup, just in case ... "
echo -n "###### $myBLUE Building archive in $myARCHIVE $myWHITE"
cd /opt/tpot
tar cvfz $myARCHIVE * 2>&1>/dev/null
if [ $? -ne 0 ];
  then
    echo " [ $myRED""NOT OK""$myWHITE ]"
    echo "###### $myBLUE""Something went wrong.""$myWHITE"" [ $myRED""NOT OK""$myWHITE ]"
    echo "Exiting.""$myWHITE"
    echo
    cd $myPATH
    exit 1
  else
    echo "[ $myGREEN"OK"$myWHITE ]"
    cd $myPATH
fi
echo
}

# Let's load docker images in parallel
function fuPULLIMAGES {
local myTPOTCOMPOSE="/opt/tpot/etc/tpot.yml"
for name in $(cat $myTPOTCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
  done
wait
echo
}

function fuUPDATER () {
local myPACKAGES="apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban genisoimage git glances grc html2text htop ifupdown iptables iw jq libcrack2 libltdl7 lm-sensors man mosh multitail net-tools npm ntp openssh-server openssl pass prips syslinux psmisc pv python-pip unattended-upgrades unzip vim wireless-tools wpasupplicant"
echo "### Now upgrading packages ..."
apt-get -y autoclean
apt-get -y autoremove
apt-get update
apt-get -y install $myPACKAGES

# Some updates require interactive attention, and the following settings will override that.
echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes

npm install "https://github.com/taskrabbit/elasticsearch-dump" -g
pip install --upgrade pip
hash -r
pip install --upgrade elasticsearch-curator yq
wget https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 -O /usr/bin/ctop && chmod +x /usr/bin/ctop
echo

echo "### Now replacing T-Pot related config files on host"
cp host/etc/systemd/* /etc/systemd/system/
cp host/etc/issue /etc/
systemctl daemon-reload
echo

echo "### Now pulling latest docker images"
echo "######$myBLUE This might take a while, please be patient!$myWHITE"
fuPULLIMAGES 2>&1>/dev/null

echo "### If you made changes to tpot.yml please ensure to add them again."
echo "### We stored the previous version as backup in /root/."
echo "### Done, please reboot."
echo
}


################
# Main section #
################

# Got root?
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    sudo ./$0
    exit
fi

# Only run with command switch
if [ "$1" != "-y" ]; then
  echo "This script will update / upgrade all T-Pot related scripts, tools and packages to the latest versions."
  echo "A backup of /opt/tpot will be written to /root. If you are unsure, you should save your work."
  echo "This is a beta feature and only recommended for experienced users."
  echo "If you understand the involved risks feel free to run this script with the '-y' switch."
  echo
  exit
fi

fuCHECK_VERSION
fuCONFIGCHECK
fuCHECKINET "https://index.docker.io https://github.com https://pypi.python.org https://ubuntu.com"
fuSTOP_TPOT
fuBACKUP
fuSELFUPDATE "$0" "$@"
fuUPDATER
