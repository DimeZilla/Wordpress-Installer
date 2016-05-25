#!/bin/bash
# This script automates the download of wordpress and auto changes the core configuration by doing the following
#	1. downloads the latest wordpress, 
#	2. unpacks it 
#	3. copies index.php to this base directory, 
#	4. copies and renames wp-content to this directory
#	5. sets up a new require_once file for wp-config.php with the new content folder configuration
#	6. sets up a new require_once file for wp-config.php with the db credentials
#	7. sets up a new require_once debug config for the wp-config.php file

#1. download process taken from http://code.tutsplus.com/articles/download-and-install-wordpress-via-the-shell-over-ssh--wp-24403
wget http://wordpress.org/latest.tar.gz
#2. extract
tar xfz latest.tar.gz & wait
rm -f latest.tar.gz & wait

#clean up extraction
read -p "What would you like to name the core wordpress folder? Enter name: " cname
mv wordpress $cname & wait

#copy the index.php file - find and replace the redirect string to include the new core folder
cp $cored/index.php . & wait
sed -i -e "s/\/wp-blog-header.php/\/$cname\/wp-blog-header.php/g" index.php

read -p "What would you like to name the content folder? Enter name: " name
mv $cname/wp-content $name & wait

read -p "This program comes with a special config folder. What would you like to name the config folder? Enter name: " config
mkdir $config

