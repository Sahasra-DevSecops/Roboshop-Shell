SG_ID="sg-000c5bbdae937d72f"
AMI_ID="ami-0220d79f3f480ecf5"
for instance in $@
do
instance_id = $( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].PrivateIpAddress' \
    --output text )
if [ $instance == "frontend" ]; then
	IP= $( 
		aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Instances[0].PublicIpAddress' \
    --output text )
 

else

IP= $( 
	aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Instances[0].PrivateIpAddress' \
    --output text 
	)

	fi
done

