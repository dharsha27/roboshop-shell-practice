#!/bin/bash 

AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE="Z02304293I0EIMA6V7PSK"
DOMAIN_NAME="devopspractice.online"


for instance in "$@"
do 
   echo "Launching the instances: $instance"
   INSTANCE_ID=$(aws ec2 run-instances \
            --image-id ami-0220d79f3f480ecf5 \
            --instance-type t3.micro \
            --security-groups "roboshop-common" "roboshop-$instance" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=MyCLIInstance}]" \
            --query 'Instances[0].InstanceId' \
            --output text)

   echo "Instance id: $INSTANCE_ID"

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
      
      # 3. Create Route 53 DNS Record
   echo "Creating DNS record for $instance.$DOMAIN_NAME..."


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

   

done





