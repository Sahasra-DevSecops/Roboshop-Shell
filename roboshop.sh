#!/bin/bash

SG_ID="sg-000c5bbdae937d72f"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z09891872RAM18EYN37Z5"
DOMAIN_NAME="daws88s.online"
for instance in $@
do
    # Fix 1: Change instance_id to InstanceId (Case Sensitive)
    instance_id=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    # Wait for the instance to be "running" so an IP is actually assigned
    aws ec2 wait instance-running --instance-ids $instance_id

    if [ "$instance" == "frontend" ]; then
        # Fix 2: Add Reservations[0] to the query path
        IP=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
			)
						RECORD_NAME="$DOMAIN_NAME" # daws88s.online

    else
        # Fix 3: Add Reservations[0] to the query path
        IP=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
			)
			RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.daws88s.online

    fi

    echo "$instance IP Address: $IP"

	aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '{
  "comment": "Update a record",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'$RECORD_NAME'",
          "Type": "A",
          "TTL": 1,
          "ResourceRecords": [
            { "Value": "'$IP'" }
          ]
        }
      }
    ]
  }'

echo "record updated for $instance"
done
