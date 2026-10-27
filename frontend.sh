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

#Installing Nginx
dnf module disable nginx -y &>> $logs_file
dnf module enable nginx:1.26 -y &>> $logs_file
dnf install nginx -y &>> $logs_file
validate $? "Installing Nginx"

#Starting Nginx
systemctl enable nginx &>> $logs_file
systemctl start nginx &>> $logs_file
validate $? "Starting Nginx"

#Remove default content
rm -rf /usr/share/nginx/html/* &>> $logs_file

#Downloading and Extracting frontend content
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>> $logs_file
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $logs_file
validate $? "Downloading and Extracting frontend content"

#Configuring roboshop.conf file
sed -i "s/DOMAIN_NAME/$domain_name/g" $script_dir/roboshop.conf
cp $script_dir/roboshop.conf /etc/nginx/default.d/roboshop.conf
validate $? "Configuring roboshop.conf"

nginx -t &>> $logs_file
validate $? "Validating Reverse Proxy Syntax"

systemctl restart nginx
validate $? "Restarting nginx"
 

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file