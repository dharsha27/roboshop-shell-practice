#!/bin/bash 

# Logs files

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p "$LOGS_FOLDER"
sudo chown -R ec2-user:ec2-user "$LOGS_FOLDER"
sudo chmod 755 "$LOGS_FOLDER"
SCRIPT_NAME=$(basename "$0")
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
MYSQL_HOST="$mysql.devopspractice.online"




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


echo "installing  maven "
dnf install maven -y  &>> "$LOGS_FILE"

id roboshop &>> "$LOGS_FILE"

if [ $? -ne 0 ]; then

      useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
      VALIDATE $? "System User roboshop  creating ... "
else 
      echo -e "Created system user roboshop already ...$Y skipping $N"
fi

rm -rf /app  &>> "$LOGS_FILE"
VALIDATE $? "Removing existing code"  &>> "$LOGS_FILE"

rm -rf /tmp/shipping.zip
VALIDATE $? "Removing existing code"  &>> "$LOGS_FILE"

mkdir -p /app &>> "$LOGS_FILE"

VALIDATE $? "Creating app directory "

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip

VALIDATE $? "Downloaded and extracted shipping code"  &>> "$LOGS_FILE"

cd /app  &>> "$LOGS_FILE"
mvn clean package  
mv target/shipping-1.0.jar shipping.jar &>> "$LOGS_FILE"
VALIDATE $? "cleaning the packages"  &>> "$LOGS_FILE"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Creating system catalogue service"

systemctl daemon-reload &>> "$LOGS_FILE"

systemctl enable shipping  &>> "$LOGS_FILE"
systemctl start shipping &>> "$LOGS_FILE"
VALIDATE $? "Enable and start catalogue " &>> "$LOGS_FILE"



dnf install mysql -y &>> "$LOGS_FILE"

VALIDATE $? "Installed MYSQL client" &>> "$LOGS_FILE"

mysql -h mysql.devopspractice.online -u root -pRoboShop@1 < /app/db/schema.sql

if [ $? -ne 0 ] ; then 
    
    mysql -h $MYSQL_HOST -u root -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -u root -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $MYSQL_HOST -u root -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Data Loaded"
else 

   echo -e " Data Already Loading ... $Y Skipping  "
fi


# systemctl enable shipping 
systemctl restart shipping
 VALIDATE $? "Enabled and restarted shipping "