#!/bin/bash
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07086101C1CVP7AT2UK4" # replace with your zone ID
DOMAIN_NAME="daws90s.shop" # replace with your domain name
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

### Validation ###
if [ $# -lt 2 ]; then
    echo -e "$R ERROR:: Atleast 2 arguments required $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

ACTION=$1
shift # first argument will be removed

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
    echo -e "$R ERROR:: First argument must be either create or delete $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

get_instance_id(){
    name=$1
    # Changed query to safely fetch exactly one string or 'None'
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text
}

for instance in "$@"
do
    INSTANCE_ID=$(get_instance_id "$instance")
    
    if [ "$ACTION" == "create" ]; then
        if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
            echo "Launching Instance: roboshop-$instance"
            
            # Note: Ensure "roboshop-$instance" security group exists in AWS before running
            INSTANCE_ID=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type t3.micro \
            --security-groups "roboshop-common" "roboshop-$instance" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
            --query 'Instances[0].InstanceId' \
            --output text)
            
            echo "Launched Instance: $INSTANCE_ID"
            aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
            echo "Instance is running: $INSTANCE_ID"
        else
            echo "roboshop-$instance already running: $INSTANCE_ID"
        fi

        # Update Route 53 Record
        if [ "$instance" == "frontend" ]; then
            # Fixed query syntax to pull a single clean string output
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
            R53_RECORD="$DOMAIN_NAME"
        else
            # Fixed query syntax to pull a single clean string output
            IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
            R53_RECORD="$instance.$DOMAIN_NAME"
        fi

        # Wrap variables cleanly inside the JSON payload to prevent syntax splitting
        aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
                \"Comment\": \"Update A record to new IP\",
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
            }"
        echo "Updated R53 record for: $instance to IP: $IP"
    else
        if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
            echo "$instance already destroyed, nothing to do..."
        else
            aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
            echo "Terminating Instance: $instance"
        fi
    fi
done
