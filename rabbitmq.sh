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

#Copying rabbit repo from local file to /etc/yum.repos.d location
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

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

#Installing rabbitmq
dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "RabbitMQ installation"

#Starting Rabbitmq
systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "Starting RabbitMQ"

#Configuring Rabbitmq
rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "Configuring Rabbitmq"

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file