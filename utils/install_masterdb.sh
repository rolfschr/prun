#!/bin/sh

die () {
    echo "ERROR: $1. Aborting!"
    exit 1
}

echo "Welcome to the prun master db service installer"
echo "This script will help you easily set up a running prun master db server

"

if [ `id -u` != "0" ] ; then
	echo "You must run this script as root. Sorry!"
	exit 1
fi

#read master database directory
_MASTER_DB_DIR="/var/lib/pmasterdb"
read -p "Please select the master database directory [$_MASTER_DB_DIR] " MASTER_DB_DIR
if [ -z "$MASTER_DB_DIR" ] ; then
	MASTER_DB_DIR=$_MASTER_DB_DIR
	echo "Selected default - $MASTER_DB_DIR"
fi
mkdir -p $MASTER_DB_DIR || die "Could not create master database directory"
MASTER_DB_DIR=$MASTER_DB_DIR"/db"
cp -rf "db" $MASTER_DB_DIR || die "Could not copy database directory"

#replace pidfile path in config file
PIDFILE="/var/run/pmasterdb.pid"
TMP_CONFIG=`mktemp`

cp -f "masterdb.cfg" $TMP_CONFIG || die "could not copy 'masterdb.cfg' to $TMP_CONFIG"
sed -i "s|masterdb.pid|$PIDFILE|g" $TMP_CONFIG
sed -i "s|\"db\"|\"$MASTER_DB_DIR\"|g" $TMP_CONFIG

#read masterdb config file
_MASTERDB_CONFIG_FILE="/etc/pmasterdb/masterdb.cfg"
read -p "Please select the masterdb config file name [$_MASTERDB_CONFIG_FILE] " MASTERDB_CONFIG_FILE
if [ -z "$MASTERDB_CONFIG_FILE" ] ; then
	MASTERDB_CONFIG_FILE=$_MASTERDB_CONFIG_FILE
	echo "Selected default - $MASTERDB_CONFIG_FILE"
fi
#try and create it
MASTERDB_CONFIG_DIR=`dirname "$MASTERDB_CONFIG_FILE"`
mkdir -p $MASTERDB_CONFIG_DIR || die "Could not create masterdb config directory"
cp -f $TMP_CONFIG $MASTERDB_CONFIG_FILE || die "Could not copy configuration file"

#read masterdb executable directory
_MASTERDB_EXE_DIR="/usr/bin"
read -p "Please select the masterdb executable directory [$_MASTERDB_EXE_DIR] " MASTERDB_EXE_DIR
if [ -z "$MASTERDB_EXE_DIR" ] ; then
	MASTERDB_EXE_DIR=$_MASTERDB_EXE_DIR
	echo "Selected default - $MASTERDB_EXE_DIR"
fi
mkdir -p $MASTERDB_EXE_DIR || die "Could not create masterdb executable directory"
cp -f "pmasterdb" $MASTERDB_EXE_DIR || die "Could not copy executable file"

#get masterdb executable path
MASTERDB_EXECUTABLE=`which pmasterdb`
if [ ! -f "$MASTERDB_EXECUTABLE" ] ; then
	echo "Could not find masterdb executable"
	exit 1
fi

INIT_TPL_FILE="utils/masterdb_init_script.tpl"
INIT_SCRIPT_DEST="/etc/init.d/pmasterdb"

MASTERDB_INIT_HEADER=\
"#/bin/sh\n
#Configurations injected by install_masterdb below....\n\n
EXEC=\"$MASTERDB_EXECUTABLE\"\n
CONF=\"$MASTERDB_CONFIG_FILE\"\n\n
###############\n\n"

MASTERDB_CHKCONFIG_INFO=\
"# REDHAT chkconfig header\n\n
# chkconfig: - 58 74\n
# description: pmasterdb is the prun master database daemon.\n
### BEGIN INIT INFO\n
# Provides: pmasterdb\n
# Required-Start: $network $local_fs $remote_fs\n
# Required-Stop: $network $local_fs $remote_fs\n
# Default-Start: 2 3 4 5\n
# Default-Stop: 0 1 6\n
# Should-Start: $syslog $named\n
# Should-Stop: $syslog $named\n
# Short-Description: start and stop pmasterdb\n
# Description: Prun master database daemon\n
### END INIT INFO\n\n"

#Generate config file from the default config file as template
#changing only the stuff we're controlling from this script
echo "## Generated by install_masterdb.sh ##" > $TMP_CONFIG

if [ -z `which chkconfig` ] ; then
	#combine the header and the template (which is actually a static footer)
	/bin/echo -e $MASTERDB_INIT_HEADER > $TMP_CONFIG && cat $INIT_TPL_FILE >> $TMP_CONFIG || die "Could not write init script to $TMP_CONFIG"
else
	#if we're a box with chkconfig on it we want to include info for chkconfig
	/bin/echo -e $MASTERDB_INIT_HEADER $MASTERDB_CHKCONFIG_INFO > $TMP_CONFIG && cat $INIT_TPL_FILE >> $TMP_CONFIG || die "Could not write init script to $TMP_CONFIG"
fi

#copy to /etc/init.d
cp -f $TMP_CONFIG $INIT_SCRIPT_DEST && chmod +x $INIT_SCRIPT_DEST || die "Could not copy masterdb init script to  $INIT_SCRIPT_DEST"
echo "Copied $TMP_CONFIG => $INIT_SCRIPT_DEST"

rm -f $TMP_CONFIG

#Install the service
echo "Installing service..."
if [ -z `which chkconfig` ] ; then 
	#if we're not a chkconfig box assume we're able to use update-rc.d
	update-rc.d pmasterdb defaults && echo "Success!"
else
	# we're chkconfig, so lets add to chkconfig and put in runlevel 345
	chkconfig --add pmasterdb && echo "Successfully added to chkconfig!"
	chkconfig --level 345 pmasterdb on && echo "Successfully added to runlevels 345!"
fi

/etc/init.d/pmasterdb start || die "Failed starting service..."

echo "Installation successful!"
exit 0

