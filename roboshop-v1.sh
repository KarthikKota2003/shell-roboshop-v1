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
done