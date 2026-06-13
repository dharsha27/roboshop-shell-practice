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

get_instance_id(){
    name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name, Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text

}

launch_instance(){

    echo "we are going to launching the  instance according to your requirement--roboshop $instance"
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-groups "roboshop-common" "roboshop-$instance" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]"\
    --query 'Instances[0].InstanceId'\
    --output text

}

for instance in "$@" 
do 

 INSTANCE_ID=$(get_instance_id "$instance")

 if [ "$ACTION" == "create" ]; then
     if [ "$INSTANCE_ID" == "None"  ]; then
       
              INSTANCE_ID=$(launch_instance) 
              echo "Launched Instance: $INSTANCE_ID"

     else
          echo "roboshop-$instance already running : $INSTANCE_ID "
     fi
 fi          




done

