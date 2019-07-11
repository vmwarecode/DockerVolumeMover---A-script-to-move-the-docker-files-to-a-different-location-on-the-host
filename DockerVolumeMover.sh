#!/bin/bash

#######################################################################################################
#Script Name	: DockerMover                                                                                             
#Description	: A script to move the docker files to a different location on the host.
#                 This script is especially codded and tested for moving docker files on HCIBench VMs.
#                 More info about HCIBench: https://labs.vmware.com/flings/hcibench                                                                                                                                                                    
#Authors       	: Xiaowei Chu (xiaoweic@vmware.com), Chen Wei (cwei@vmware.com)                                                                                      
#######################################################################################################

src='/var/lib/docker'
dst='/opt/output/results/DONT_TOUCH'

while getopts "hs:d:" opt; do
  case ${opt} in
    h )
      echo Use the -s and -d flags to set the source and destination locations of docker containers. 
      echo If no values are set, by default, this tool moves the docker containers from /var/lib/docker to /opt/output/results/DONT_TOUCH.
      exit
      ;;
    s )
      src="$OPTARG"
      ;;
    d )
      dst="$OPTARG"
      ;;
  esac
done



if [ "${dst: -1}" == "/" ] 
then
    dst="${dst::-1}"
fi

if [ "${src: -1}" == "/" ]
then
    src="${src::-1}"
fi

read -p "Are you sure to move the docker containers from ${src} to ${dst} ? (y/n): " yn
case $yn in
    y ) ;;
    * ) 
        echo Exiting...
        exit;;
esac


if [ -L $src ]
then
  echo "The source is a symbolic link. Please check if the docker containers have already been moved."
  exit
fi


echo Docker containers are being moved ... 

#Create the destination directory and set the permission
if [ ! -d "$dst" ]
then
  mkdir -p $dst
fi

chown root:root $dst && chmod 701 $dst

#Stop the docker containers and docker daemon.
docker stop $(docker ps -q)
systemctl stop docker

#Create service folder and config file.
serv_path="/etc/systemd/system/docker.service.d"
mkdir -p $serv_path
cat > "${serv_path}/docker.conf" << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -g $dst/docker/
EOF

#Reload the docker daemon config
systemctl daemon-reload

#Move the docker files to new location
mv ${src}/ ${dst}/

#Create the symbolic link
ln -s $dst/docker $src

#Start docker daemon
systemctl start docker
echo Done!

