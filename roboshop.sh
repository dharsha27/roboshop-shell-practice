#!/bin/bash 

# AMI_ID="ami-0220d79f3f480ecf5"
# HOSTED_ZONE="Z02304293I0EIMA6V7PSK"
# DOMAIN_NAME="devopspractice.online"

# # colours
# USERID=$(id -u)
# R="\e[31m]"
# G="\e[32m]"
# Y="\e[33m]"
# N="\e[0m]"
# TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# for instance in "$@"
# do 
#    echo "Launching the instances: $instance"
#    INSTANCE_ID=$(aws ec2 run-instances \
#             --image-id ami-0220d79f3f480ecf5 \
#             --instance-type t3.micro \
#             --security-groups "roboshop-common" "roboshop-$instance" \
#             --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
#             --query 'Instances[0].InstanceId' \
#             --output text)

#    echo "Instance id: $INSTANCE_ID"

#    if [ "$instance" == "frontend" ]; then
#       IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
#             --query 'Reservations[*].Instances[*].PublicIpAddress' \
#             --output text)
#       R53_RECORD="$DOMAIN_NAME"
#    else
#       IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
#             --query 'Reservations[*].Instances[*].PrivateIpAddress' \
#             --output text)
#       R53_RECORD="$instance.$DOMAIN_NAME"
#    fi
      
#       # 3. Create Route 53 DNS Record
#    echo "Creating DNS record for $instance.$DOMAIN_NAME..."


#    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" --change-batch "
# {
#   \"Comment\": \"Update a new IP record\",
#   \"Changes\": [
#     {
#       \"Action\": \"UPSERT\",
#       \"ResourceRecordSet\": {
#         \"Name\": \"$R53_RECORD\",
#         \"Type\": \"A\",
#         \"TTL\": 1,
#         \"ResourceRecords\": [
#           { 
#             \"Value\": \"$IP\"
#           }
#         ]
#       }
#     }
#   ]
# }
# "

# done


AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE="Z02304293I0EIMA6V7PSK"
DOMAIN_NAME="devopspractice.online"

# REPLACE THESE WITH YOUR ACTUAL AWS SECURITY GROUP IDs (sg-...)
SG_COMMON="roboshop-common"   # Your roboshop-common SG ID
SG_DYNAMIC="roboshop-$instance"  # Your instance-specific SG ID (or dynamically fetch it)

# Colours
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
shift 

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
     echo -e "${R}ERROR: First argument should either be 'create' or 'delete'${N}"
     echo "USAGE: $0 [create/delete] [Instance 1] [Instance 2...]"
     exit 1
fi

get_instance_id(){
    local name=$1
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text
}

launch_instance(){
    local name=$1
    echo -e "${Y}Launching the instance: roboshop-$name...${N}" >&2
    
    # Changed --security-groups to --security-group-ids
    aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_COMMON" "$SG_DYNAMIC" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$name}]" \
        --query 'Instances[0].InstanceId' \
        --output text
}

### Main Loop ###

for instance in "$@" 
do 
    echo -e "\n${G}--- Processing: $instance ---${N}"
    INSTANCE_ID=$(get_instance_id "$instance")

    if [ "$ACTION" == "create" ]; then
        if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
            INSTANCE_ID=$(launch_instance "$instance") 
            
            # Stop execution if instance creation failed
            if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
                echo -e "${R}Error: Instance launch failed for roboshop-$instance. Skipping Route 53 step.${N}"
                continue
            fi
            
            echo -e "${G}Launched Instance: $INSTANCE_ID${N}"
            
            echo "Waiting for instance to initialize and acquire an IP address..."
            aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
        else
            echo -e "${Y}This instance ($instance) already exists with ID: $INSTANCE_ID${N}"
        fi         

        # Fetch IP addresses
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

        # Validation to prevent Route 53 payload errors if IP is blank
        if [ "$IP" == "None" ] || [ -z "$IP" ]; then
            echo -e "${R}Error: Could not retrieve a valid IP for $instance. Skipping DNS registration.${N}"
            continue
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
        echo -e "${G}Updated Route 53 record for: $R53_RECORD -> $IP${N}"

    else
        # Delete Action
        if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then 
            echo -e "${Y}roboshop-$instance is not running or doesn't exist.${N}"
        else 
            aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null
            echo -e "${G}Successfully sent termination request for: $INSTANCE_ID${N}"
        fi
    fi
done



