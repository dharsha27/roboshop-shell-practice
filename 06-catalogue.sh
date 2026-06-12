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
    if [ "$1" -ne 0 ]; then 
       echo -e "$TIMESTAMP  [ERROR] $2 ....$R FAILURE $N " | tee -a "$LOGS_FILE"
    else
       echo -e "$TIMESTAMP  [INFO] $2 ....$G SUCCESS $N " | tee -a "$LOGS_FILE"
    fi
}


echo "disabling node js "
dnf module disable nodejs -y &>> "$LOGS_FILE"

echo "enabling node js "
dnf module enable nodejs:20 -y  &>> "$LOGS_FILE"

echo "installing  node js "
dnf install nodejs -y  &>> "$LOGS_FILE"

id roboshop &>> "$LOGS_FILE"

if [ $? -ne 0 ]; then

      useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
      VALIDATE $? "System User roboshop  creating ... "
else 
      echo "Created system user roboshop already ...$Y skipping $N"
fi


mkdir -p /app &>> "$LOGS_FILE"

VALIDATE $? "Creating app directory "

