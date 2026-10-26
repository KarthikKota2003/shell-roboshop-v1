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

#Installing Nodejs
dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Installing Nodejs"

#Creating system user
id roboshop &>> $logs_file
if (( $? != 0 ));then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating System User"
else
    echo -e "User already exists ... ${Y}SKIPPING${N}" 
fi

#Creating app directory
mkdir -p /app
validate $? "Creating App Directory"

#Downloading and unzipping code
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Unzipping code"

#Installing dependencies
npm install &>> $logs_file
validate $? "Installing dependencies"

#Creating SystemD file
sed -i "s/DOMAIN_NAME/$domain_name/g" $script_dir/catalogue.service
cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service

#Starting catalogue service
systemctl daemon-reload
systemctl enable catalogue &>> $logs_file
systemctl start catalogue
validate $? "Starting Catalogue Service"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo

#Installing MongoDB client
dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing MongoDB Client"

#Checking if data exists or not
if (( $(mongosh --host "mongodb.$domain_name" --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()') != 11 ));then
    #Loading Data
    mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>> $logs_file
    validate $? "Loading Data into MongoDB"
else
    echo -e "Data already exists ... ${Y}SKIPPING${N}"
fi

#Restarting catalogue service to refresh service file again
systemctl restart catalogue
validate $? "Restarting Catalogue"

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file