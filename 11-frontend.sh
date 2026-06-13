#!/bin/bash 

# Logs files

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p "$LOGS_FOLDER"
sudo chown -R ec2-user:ec2-user "$LOGS_FOLDER"
sudo chmod 755 "$LOGS_FOLDER"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD




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
    if [ "$1" -ne 0 ]; then 
       echo -e "$TIMESTAMP  [ERROR] $2 ....$R FAILURE $N " | tee -a "$LOGS_FILE"
    else
       echo -e "$TIMESTAMP  [INFO] $2 ....$G SUCCESS $N " | tee -a "$LOGS_FILE"
    fi
}


dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y

VALIDATE $? "Installed nginx"


rm -rf /usr/share/nginx/html/* 

VALIDATE $? "Removing Default code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip

VALIDATE $? "Downloaded and extracted  nginx"

rm -rf /etc/nginx/nginx.conf

VALIDATE $? "removeing nginx file"


cp nginx.conf /devopspractice.online
VALIDATE $? "copy coded to that nginx"



systemctl enable nginx 
systemctl Restart nginx 

VALIDATE $? "Enabled and restarted nginx"

