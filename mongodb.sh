#!/bin/bash

# Creating logs folder and logs file
logs_folder="/var/log/roboshop"
logs_file=${logs_folder}/${0}.log

mkdir -p $logs_folder 

#Setting colors for log printing
R="\e[31m"
G="\e[32m" 
Y="\e[33m"
N="\e[0m"

#Copying mongo repo from local file to /etc/yum.repos.d location
cp mongo.repo /etc/yum.repos.d/mongo.repo

#Function to validate command execution
validate(){
    if (( $1 != 0));then
        echo -e "${2} is ${R}FAILED${N}" | tee -a $logs_file
    else
        echo -e "${2} is ${G}SUCCESS${N}" | tee -a $logs_file 
}

#Installing mongodb
dnf install mongodb-org -y &>> $logs_file
validate $? "Mongodb installation"

#Starting Mongodb
systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "Starting mongodb"

