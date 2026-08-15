#!/bin/bash
IMAGE_ID="ami-0e0416d387552f0b1"
KEY_NAME="key-02cb5f478801a2d5b"
SECURITY_GROUP_ID="sg-0fc3b5d7044d4a2cb"
#DNS variables
DOMAIN_NAME="roboshopservice.store"
HOSTED_ZONE_ID="Z0998832SJ6BSEHIHVRJ"


for i in "$@"
do  
    if [[ "$i" == "mongodb" || "$i" == "mysql" ]]
    then
        INSTANCE_TYPE="t3.medium"
    else
        INSTANCE_TYPE="t3.micro"
    fi
    echo "creating $i instance"
    INSTANCE_ID=$(aws ec2 run-instances \
     --image-id "$IMAGE_ID" \
     --instance-type "$INSTANCE_TYPE" \
     --key-name "$KEY_NAME" \
     --security-group-ids "$SECURITY_GROUP_ID" \
     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
     --query '.Instances[0].InstanceId' \
     --output text)
    echo "created $i instance: $INSTANCE_ID"
    sleep 5

    if [[ "$i" == "web" ]]
    then
        IP_ADDRESS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    else
        IP_ADDRESS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
    fi

    echo "$i IP address: $IP_ADDRESS"

    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '
    {
            "Changes": [{
            "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": "'$i.$DOMAIN_NAME'",
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
                        }}]
    }
    '
done


