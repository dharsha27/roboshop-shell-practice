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


# Installing Mysql

dnf install mysql-server -y

VALIDATE $? "Installing Mysql server"

systemctl enable mysqld &>> "$LOGS_FILE"
systemctl start mysqld  &>> "$LOGS_FILE"
VALIDATE $? "Enable and start Mysql server" 

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setting up to root access" 












