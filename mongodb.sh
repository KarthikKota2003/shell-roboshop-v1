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
B="\e[34m"

#Copying mongo repo from local file to /etc/yum.repos.d location
cp mongo.repo /etc/yum.repos.d/mongo.repo

timestamp(){
    date "+%F %T"
}

#Function to validate command execution
validate(){
    if (( $1 != 0));then
        echo -e "${2} is ${R}FAILED${N}" | tee -a $logs_file
    else
        echo -e "${2} is ${G}SUCCESS${N}" | tee -a $logs_file 
    fi
}

echo -e "$(timestamp) ${B}[INFO]${N} ==== Script started execution ====" | tee -a $logs_file

#Checking if the script is running under root user or not
user_id=$(id -u)
if (( $user_id != 0 )); then
    echo "This script is not running under root user, please check..." | tee -a $logs_file
else
    echo "Running under root user..." | tee -a $logs_file
fi

#Installing mongodb
dnf install mongodb-org -y &>> $logs_file
validate $? "Mongodb installation"

#Starting Mongodb
systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "Starting mongodb"

#Configuring mongodb
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Configuring mongodb"

#Restarting mongodb
systemctl restart mongod &>> $logs_file
validate $? "Restarting mongodb"

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file