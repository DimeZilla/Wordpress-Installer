#!/bin/bash
# This script automates the download of wordpress and auto changes the core configuration by doing the following
#	1. downloads the latest wordpress, 
#	2. unpacks it 
#	3. copies index.php to this base directory, 
#	4. copies and renames wp-content to this directory
#	5. sets up a new require_once file for wp-config.php with the new content folder configuration
#	6. sets up a new require_once file for wp-config.php with the db credentials
#	7. sets up a new require_once debug config for the wp-config.php file

#Lets first figure out which OS we are in so that we can discern which package manager to use for some basic scipt dependencies
OS=$(lsb_release -si)
#1. download process taken from http://code.tutsplus.com/articles/download-and-install-wordpress-via-the-shell-over-ssh--wp-24403
wget http://wordpress.org/latest.tar.gz
#2. extract
tar xfz latest.tar.gz & wait
rm -f latest.tar.gz & wait

#clean up extraction
read -p "What would you like to name the core wordpress folder? Enter name: " cname
mv wordpress $cname & wait

#copy the index.php file - find and replace the redirect string to include the new core folder
cp $cname/index.php . & wait
sed -i -e "s/\/wp-blog-header.php/\/$cname\/wp-blog-header.php/g" index.php

read -p "What would you like to name the content folder? Enter name: " name
mv $cname/wp-content $name & wait

read -p "This program comes with a special config folder. What would you like to name the config folder? Enter name: " config
mkdir $config

#now lets set up the db connection credentials
printf "Now we need to set up your db credentials.\n"
read -p "What is your database Host Name? " host
read -p "What is your database stack name? " stackname
read -p "What is your database username? " username
read -p "What is your database user password? " password
read -p "What do you want your custom table prefixes to be? " tableprefix
cat > $config/dbcreds.php <<END
<?php
//This file is our database credentials and is required by wp-config.php
/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

define('DB_NAME', '$host'); 
define('DB_USER', '$username');
define('DB_PASSWORD', '$password'); 
define('DB_HOST', '$stackname');

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix  = '$tableprefix';

?>
END

#lets get our salts
if [ -f $config/salts.php ]; then 
	rm $config/salts.php 
fi

touch $config/salts.php
echo '<?php' >> $config/salts.php
if ! [ -x "$(command -v curl)" ] 
then 
	if [ $OS = "Ubuntu" ] 
	then
		apt-get install -y curl & wait
	else
		yum install -y curl & wait
	fi
fi
curl https://api.wordpress.org/secret-key/1.1/salt/ >> $config/salts.php & wait
echo '?>' >> $config/salts.php

#lets set up debug
read -p "Do you want this installation to be in debug mode? [Y|n]" debug
touch $config/debug.php
if [ $debug = 'Y' ]; then
cat > $config/debug.php <<END
<?php
/*Debug settings*/
define('WP_DEBUG', true);
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
?>
END
else
cat > $config/debug.php <<END
<?php
/*Debug settings*/
define('WP_DEBUG', false);
?>
END
fi

if [ -f $cname/wp-config.php ]; then
	rm $cname/wp-config.php
fi

touch $cname/wp-config.php
cat > $cname/wp-config.php <<END
<?php
/* 
 * This is our custom wp-config.php file your custom files come from the $config folder 
 * It is recommended that the first three files required below are done so in that order
 * after that there is a foreach that will grab any other file that you may add
 * - if you want to add those files in a particular order add it using a require_once statement
 * - here we are using a require_once statement because php will check for us if the file is already included and will skip it if it is already included
 */

/** Now we are going to define where our wp-content directory is **/
define( 'WP_CONTENT_DIR',  dirname(__DIR__) . '/$name' );
define( 'WP_CONTENT_URL', '/$name' );

// this will fix the issue with the relative paths
\$parent = dirname(__DIR__);

require_once( \$parent . '/$config/dbcreds.php');
require_once( \$parent . '/$config/salts.php');
require_once( \$parent . '/$config/debug.php');

foreach (scandir(\$parent . '/$config') as \$filename) {
    \$path = \$parent . '/$config/' . \$filename;
    if (is_file(\$path)) {
        require_once(\$path);
    }
}

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

END

#very last step - lets get a silence is golden index.php and put it in the config folder
if [ -f $name/index.php ]; then
	cp $name/index.php $config/index.php
fi