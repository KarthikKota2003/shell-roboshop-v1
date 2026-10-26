#!/bin/bash

domain_name="kartheekops92.online"
script_dir=$(dirname "$(realpath $0)")

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

timestamp(){
    date "+%F %T"
}

#Function to validate command execution
validate(){
    if (( $1 != 0));then
        echo -e "$(timestamp) ${R}[ERROR]${N} ${2} is ${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2} is ${G}SUCCESS${N}" | tee -a $logs_file 
    fi
}

echo -e "$(timestamp) ${B}[INFO]${N} ==== Script started execution ====" | tee -a $logs_file

#Checking if the script is running under root user or not
user_id=$(id -u)
if (( $user_id != 0 )); then
    echo "This script is not running under root user, please check..." | tee -a $logs_file
    exit 1
else
    echo "Running under root user..." | tee -a $logs_file
fi

#Removing old code
rm -rf /app
validate $? "Removing Old Code"

#Installing Java and Maven
dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing Java and Maven"

#Configuring java version
alternatives --set java /usr/lib/jvm/java-25-openjdk/bin/java 
validate $? "Configuring Java Version"

#Configuring Java Version in Maven
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Configuring Java Version in Maven"
 

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file