#!/bin/bash

#This file create a laravel project on requested folder
#and set all the configrtion nessesery to run the project on a web browser

#Check if user is root user
#Only display if the UID does NOT match 1000
if [[ ${UID} -ne 0 ]]
then
 echo "Please run script with root user"
 exit 1
fi

#Ask the user for a project name
read -p "Please provide a project name: " FOLDER

#Ask the user for a git repository
read -p "Please provide a GitHub repository url: " REMOTE
 
#Set an app folder variable
APP_FOLDER="/var/www/${FOLDER}/"

#Composer install laravel project folder
composer create-project --prefer-dist laravel/laravel ${APP_FOLDER}

#Assign the proper ownership over the Laravel files and directories:
chown www-data: -R ${APP_FOLDER}

#Rename the .env.example file into .env 
mv "${APP_FOLDER}.env.example" "${APP_FOLDER}.env"

#Direct any requests for the project website to this computer and send them the local server
echo "127.0.1.1       ${FOLDER}" >> /etc/hosts

#Create an Apache virtual host file so the domain can serve Laravel.
touch "/etc/apache2/sites-available/${FOLDER}.conf"

#Append this text to the end of the text file
USER_NAME=${HOME#*/home/}
echo "<VirtualHost *:80>

    <Directory ${APP_FOLDER}public/>
               Options Indexes FollowSymLinks MultiViews
               AllowOverride All
               Order allow,deny
               allow from all
   </Directory>

   ServerAdmin ${USER_NAME}@localhost
   ServerName ${FOLDER}
   ServerAlias www.${FOLDER}
   DocumentRoot ${APP_FOLDER}public/
   ErrorLog ${APACHE_LOG_DIR}/error.log
   CustomLog ${APACHE_LOG_DIR}/access.log combined


</VirtualHost>" >> "/etc/apache2/sites-available/${FOLDER}.conf"

#Enable the site:
a2ensite ${FOLDER}.conf

#Restart Apache so the changes can take effect:
service apache2 reload

###### Set File permissions #####

#Set your user as owner
chown -R ${USER_NAME}:www-data ${APP_FOLDER}

#Set all your files to 644
find ${APP_FOLDER} -type f -exec chmod 644 {} \;

#Set all directories to 755
find ${APP_FOLDER} -type d -exec chmod 775 {} \;
 
#Give the webserver the rights to read and write to storage and cache
chgrp -R www-data ${APP_FOLDER}bootstrap/cache/
chmod -R ug+rwx ${APP_FOLDER}bootstrap/cache/

###### Generate an encryption key ######

#Add laravel app key to variable
CURRENT_DIR=$PWD;
cd ${APP_FOLDER}
APP_KEY=$(php artisan key:generate)
 
#Filter the string  
STR=${APP_KEY#*[}
FILTERED_KEY=${STR%]*}
NEW_TEXT="'key' => env('APP_KEY', '${FILTERED_KEY}'),"

###### Set GitHub repository #######

#Initialize the Git repository.
git init

#Add the files in to the local repository.
git add .

#Commit the files that staged in your local repository.
git commit -m "First commit"

#Add the URL for the remote repository where your local repository will be pushed.
git remote add origin ${REMOTE}

#Push the changes in your local repository to GitHub.
git push -u origin master

#Return to current directory
cd ${CURRENT_DIR}

#Add the key to laravel project
PATH_TO_FILE=${APP_FOLDER}config/app.php
sed -i '/'\''APP_KEY'\''/a'"${NEW_TEXT}"'' ${PATH_TO_FILE}

#Prompt the user the the installtion is end
CYAN='\e[96m'
echo -e "${CYAN}###########################################################"
echo -e "${CYAN}###                                                     ###"
echo -e "${CYAN}###     Larvel Project ${FOLDER} has been install        ###"
echo -e "${CYAN}###        Just enter http://${FOLDER}/                  ###"
echo -e "${CYAN}###                 Happy Coding!!!                     ###"
echo -e "${CYAN}###                                                     ###"
echo -e "${CYAN}###########################################################"

exit 0
