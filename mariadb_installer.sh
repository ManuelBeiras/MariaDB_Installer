#!/bin/bash
#########################################################################################################
##MariaDB installation script 											                               ##
##Date: 05/02/2022                                                                                     ##
##Version 1.0:  Allows simple installation of MariaDB.							                       ##
##        If the installation of all components is done on the same machine                            ##
##        a fully operational version remains. If installed on different machines                      ##
##        it is necessary to modify the configuration manually.                                        ##
##        Fully automatic installation only requires a password and database change.                   ##
##                                                                                                     ##
##Authors:                                                                                             ##
##			Manuel José Beiras Belloso																   ##
#########################################################################################################
# Initial check that validates if you are root and if the operating system is Ubuntu
function initialCheck() {
	if ! isRoot; then
		echo "The script has to be executed as roott"
		exit 1
	fi
}

# Function that checks to run the script as root
function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
	checkOS
}

# Function that checks the operating system
function checkOS() {
	source /etc/os-release
	if [[ $ID == "ubuntu" ]]; then
		OS="ubuntu"
		MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
		if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
			echo "⚠️ This script is not tested on your version of Ubuntu. Do you want to continue?"
			echo ""
			CONTINUE='false'
			until [[ $CONTINUE =~ (y|n) ]]; do
				read -rp "Continue? [y/n]: " -e CONTINUE
			done
			if [[ $CONTINUE == "n" ]]; then
				exit 1
			fi
		fi
		QuestionsDB
	else
		echo "Your operating system is not Ubuntu, in case it is Centos you can continue from here. Press [Y]"
		CONTINUE='false'
		until [[ $CONTINUE =~ (y|n) ]]; do
			read -rp "Continue? [y/n]: " -e CONTINUE
		done
		if [[ $CONTINUE == "n" ]]; then
			exit 1
		fi
		OS="centos"
		QuestionsDB
	fi
}

function QuestionsDB {
    echo "What do you want to do"
    echo "1. Install MariaDB."
    echo "2. Delete everything."
    echo "3. exit."
    read -e CONTINUE
    if [[ CONTINUE -eq 1 ]]; then
        installMariaDB
    elif [[ CONTINUE -eq 2 ]]; then
        deleteAll
    elif [[ CONTINUE -eq 3 ]]; then
        exit 1
    else
        echo "invalid option !"
        QuestionsDB
    fi
}

function installMariaDB() {
    if [[ $OS == "ubuntu" ]]; then
        if dpkg -l | grep mariadb > /dev/null; then
            echo "Mariadb is already installed on your system."
            echo "The installation does not continue."
        else
            apt-get -y update && apt-get -y upgrade && apt-get -y install software-properties-common
            ## Add PGP key of mariadb.
            apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
            add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'
            apt -y update && apt -y upgrade
            # Install mariadb.
            apt -y install mariadb-server mariadb-client
            # Restart service to fix error: ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/run/mysqld/mysqld.sock' (2)
            service mariadb restart
            echo ""
            echo ""
            echo "We automate mysql_secure_installation, user: root, password: abc123., never show username or password production. Just test pourpose."
            echo ""
            echo ""
            # Change the root password?
            mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('abc123.');FLUSH PRIVILEGES;"
            # Remove anonymous users
            mysql -e "DELETE FROM mysql.user WHERE User='';"
            # Disallow root login remotely?
            mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
            # Remove test database and access to it?
            mysql -e "DROP DATABASE test;DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"
            # Reload privilege tables now?
            mysql -e "flush privileges;"
            ###############################Edit all these commands to your needs#####################################
            echo "Create database requested"
            mysql -u root -p -e "CREATE DATABASE database;"
            echo "Create requested user"
            mysql -u root -p -e "CREATE USER user@localhost IDENTIFIED BY 'password';GRANT ALL PRIVILEGES ON database.* TO user@localhost;FLUSH PRIVILEGES;"
            echo "Mariadb installed"
            QuestionsDB
        fi
    fi
}

function deleteAll() {
    apt-get -y remove mariadb-server mariadb-client software-properties-common  
    apt-get -y  purge mariadb-server mariadb-client software-properties-common
    apt-get -y  purge mariadb-server-*
    apt-get -y  purge mariadb-server-10.3
    apt-get -y  purge mariadb-server-10.5
    apt-get -y  purge mariadb-client-*
    apt-get -y  purge mariadb-common
    echo "All uninstalled."
    exit 1
}

initialCheck