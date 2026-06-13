#!/bin/bash 

AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE="Z02304293I0EIMA6V7PSK"
DOMAIN_NAME="devopspractice.online"

# colours
USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")


### Validation  ###

if [ $# -lt 2 ]; then

     echo -e " $R Error : Atleast 2 arguments required  "
     echo -e " USAGE : $0 [create/delete] [Instance 1][Instance 2...]  "
     exit 1

fi


ACTION=$1

shift # first argument will be removed

if [  "$ACTION" != "create"  ] && [  "$ACTION" != "delete"  ] ;then
 
     echo  -e " $R ERROR : First argument should either create or delete $N "
     echo     " USAGE : $0 [create/delete] [Instance 1][Instance 2...]  "
     exit 1
fi



