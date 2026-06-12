#!/bin/bash 


# Logs files

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p "$LOGS_FOLDER"
sudo chown -R ec2-user:ec2-user "$LOGS_FOLDER"
sudo chmod 755 "$LOGS_FOLDER"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"




# colours
USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ];then  
      echo -e " $TIMESTAMP $R Please run script with root access...$N" | tee -a "$LOGS_FILE"
      exit 1
else
     echo -e "$TIMESTAMP $G OK you are running with root acceess, go head..."
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then 
       echo -e "$TIMESTAMP  [ERROR] $2 ....$R FAILURE $N " | tee -a "$LOGS_FILE"
    else
       echo -e "$TIMESTAMP  [INFO] $2 ....$G SUCCESS $N " | tee -a "$LOGS_FILE"
    fi
}



cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added Mongo repos"


# Installing Redis


dnf module disable redis -y
dnf module enable redis:7 -y
echo "$TIMESTAMP [INFO ]Installing Redis.." | tee -a "$LOGS_FILE"

dnf install redis -y 
VALIDATE $? "Installing Redis" 

# sed -i -e "s/127.0.0.0/0.0.0.0/g"  -e /protected-mode/ c protected-mode no /etc/redis/redis.conf

# Adjust Configuration for Remote Access and Disable Protected Mode
echo -e "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Editing /etc/redis/redis.conf settings..." | tee -a "$LOGS_FILE"
sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' -e 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>> "$LOGS_FILE" 
VALIDATE $? "Allowing remote changes in config file"




systemctl enable redis 
systemctl start redis 

VALIDATE $? "Redis restarted "





