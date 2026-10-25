#!/bin/bash

#Storing values of constants
ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="kartheekops92.online"
hosted_zone_id="Z055771213OK2D1UJZPAE"

for instance in $@
do 
    echo "Creating instance $instance"
done