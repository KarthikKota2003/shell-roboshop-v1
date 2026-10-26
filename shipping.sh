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
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "Unzipping code"

#Installing dependencies
mvn clean package &>> $logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "Moving jar file"

#Installing mysql client
dnf install mysql -y &>> $logs_file
validate $? "Installing MySQL Client"

data_count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file)
if [ -z "$data_count" ] || [ "$data_count" -eq 0 ];then
    #Loading master data
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $logs_file
    validate $? "Loading master data"
else
    echo -e "Data already exists ... ${Y}SKIPPING${N}"
fi

#Creating app user
mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $logs_file
validate $? "Creating app user"

sed -i "s/DOMAIN_NAME/$domain_name/g" $script_dir/shipping.service
cp $script_dir/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload
systemctl enable shipping &>> $logs_file
systemctl restart shipping &>> $logs_file
validate $? "Starting/Restarting Shipping"
 

echo "Total time for script execution is $SECONDS"
echo -e "$(timestamp) ${B}[INFO]${N} ==== Script completed execution ====" | tee -a $logs_file