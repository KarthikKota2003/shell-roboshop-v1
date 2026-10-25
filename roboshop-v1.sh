#!/bin/bash

#Storing values of constants
ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="kartheekops92.online"
hosted_zone_id="Z055771213OK2D1UJZPAE"

for instance in $@
do 
    echo "Creating instance $instance"

    #Creating EC2 instance and extracting instance id
    instance_id=$(
        aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --security-groups "roboshop-common" "roboshop-$instance" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text
    )

    echo "This is the instance id of $instance : $instance_id"

    #Querying IP Address with instance id and setting r53 record
    if (( $instance != "frontend" )); then
        IP=$(
        aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query "Reservations[*].Instances[*].PrivateIpAddress" \
        --output text
        )
        r53_record="${instance}.${domain_name}"
    else
        IP=$(
        aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text
        )
        r53_record="$domain_name"
    fi

    echo $r53_record

    #Updating Route53 record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $hosted_zone_id \
        --change-batch '{
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$r53_record'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{"Value": "'$IP'"}]
                }
            }]
        }'

done