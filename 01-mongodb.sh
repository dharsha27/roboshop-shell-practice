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


# Installing mongodb

 dnf clean all


echo "$TIMESTAMP [INFO ]Installing mongodb.." | tee -a "$LOGS_FILE"

dnf install -y mongodb-org  &>> "$LOGS_FILE" 

# Adjust Configuration for Remote Access and Disable Protected Mode

echo -e "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Editing /etc/redis/redis.conf settings..." | tee -a "$LOGS_FILE"
sed -i -e 's/127.0.0.1/0.0.0.0/g'  /etc/mongod.conf &>> "$LOGS_FILE" 
VALIDATE $? "Allowing remote changes in config file"


echo "Mongodb enabling"
 systemctl enable mongod
 echo "Mongodb starting"
 systemctl start mongod
 echo "Mongodb restarting"
 systemctl restart mongod

VALIDATE $? "Installing MongoDB" 


