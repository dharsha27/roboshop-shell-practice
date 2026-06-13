#!/bin/bash 

AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE="Z02304293I0EIMA6V7PSK"
DOMAIN_NAME="devopspractice.online"

# Colours (Fixed trailing brackets in escape codes)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

### Validation ###

if [ $# -lt 2 ]; then
     echo -e "${R}Error: At least 2 arguments required${N}"
     echo "USAGE: $0 [create/delete] [Instance 1] [Instance 2...]"
     exit 1
fi

ACTION=$1
shift # first argument will be removed

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
     echo -e "${R}ERROR: First argument should either be 'create' or 'delete'${N}"
     echo "USAGE: $0 [create/delete] [Instance 1] [Instance 2...]"
     exit 1
fi

get_instance_id(){
    local name=$1
    # Returns 'None' if not found or not running
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text
}

launch_instance(){
    local instance=$1
    echo -e "Launching the instance according to your requirement: roboshop-$instance" >&2
    
    # FIXED: Security groups must be listed as space-separated items for a single flag
    aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
}

for instance in "$@" 
do 
    INSTANCE_ID=$(get_instance_id "$instance")

    if [ "$ACTION" == "create" ]; then
        # if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
            # Pass the current instance name to the function
            INSTANCE_ID=$(launch_instance "$instance") 
            echo "Launched Instance ID: $INSTANCE_ID"
            
            # CRITICAL: Wait until the instance is running, otherwise IP lookup will fail
            echo "Waiting for instance to enter running state..."
            aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
        # else
            echo -e "${Y}This instance roboshop-$instance is already running (ID: $INSTANCE_ID)${N}"
        # fi         

        # Fetch IP Address
        if [ "$instance" == "frontend" ]; then
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)
            R53_RECORD="$DOMAIN_NAME"
        else
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text)
            R53_RECORD="$instance.$DOMAIN_NAME"
        fi     

        # Validate that IP address is not empty or 'None' before updating Route 53
        if [ -z "$IP" ] || [ "$IP" == "None" ]; then
            echo -e "${R}Error: Could not retrieve IP address for $instance. Route 53 skipped.${N}"
            continue
        fi

        # Update Route 53 Record
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
        echo "Updated R53 record for: $R53_RECORD -> $IP"

    else
        # Delete Action
        if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then 
            echo -e "${Y}roboshop-$instance is not running or doesn't exist.${N}"
        else 
            aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
            echo "Successfully requested termination for Instance: $INSTANCE_ID"
        fi
    fi
done
