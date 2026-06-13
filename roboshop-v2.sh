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
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name, Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text

}

# launch_instance(){
    
#     echo -e "we are going to launching the  instance according to your requirement--roboshop $instance" >&2
#     aws ec2 run-instances \
#     --image-id $AMI_ID \
#     --instance-type t3.micro \
#     --security-groups "roboshop-common" "roboshop-$instance" \
#     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]"\
#     --query 'Instances[0].InstanceId' \
#     --output text

# }


for instance in "$@" 
do 

   INSTANCE_ID=$(get_instance_id "$instance")

 if [ "$ACTION" == "create" ]; then
       
     if [ "$INSTANCE_ID" == "None"  ]; then
                INSTANCE_ID=$(aws ec2 run-instances \
                --image-id $AMI_ID \
                --instance-type t3.micro \
                --security-groups "roboshop-common" "roboshop-$instance" \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]"\
                --query 'Instances[0].InstanceId' \
                --output text)

            
              echo "Launched Instance: $INSTANCE_ID"
     else
          echo "This instance $instance already created , this is the instance_id =$INSTANCE_ID... so please check it your end "
     fi         
       
       sleep 5

          if [ "$instance" == "frontend" ]; then
                    IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                    --output text)
                    R53_RECORD="$DOMAIN_NAME"
          else
                     IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                     --query 'Reservations[*].Instances[*].PrivateIpAddress' \
                     --output text)
                    R53_RECORD="$instance.$DOMAIN_NAME"
          fi     

           aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" --change-batch "
{
  \"Comment\": \"Update a new IP record\",
  \"Changes\": [
    {
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$R53_RECORD\",
        \"Type\": \"A\",
        \"TTL\": 1,
        \"ResourceRecords\": [
          { 
            \"Value\": \"$IP\"
          }
        ]
      }
    }
  ]
}
"   
        echo "Updated R53 record for : $instance"
   

     else

           if [ $INSTANCE_ID == "None" ]; then 
                 echo -  "$Y roboshop-$instance already running : $INSTANCE_ID "
           else 
                aws ec2 terminate-instances --instance-ids $INSTANCE_ID
                 echo " Successfully Terminated the Instances : $INSTANCE_ID"

           fi
fi



done

