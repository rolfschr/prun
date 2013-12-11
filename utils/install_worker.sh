#!/bin/sh

die () {
    echo "ERROR: $1. Aborting!"
    exit 1
}

echo "Welcome to the prun worker service installer"
echo "This script will help you easily set up a running prun worker

"

if [ `id -u` != "0" ] ; then
	echo "You must run this script as root. Sorry!"
	exit 1
fi

#replace pidfile path in config file
PIDFILE="/var/run/pworker.pid"
TMP_CONFIG=`mktemp`

cp -f "worker.cfg" $TMP_CONFIG || die "could not copy 'worker.cfg' to $TMP_CONFIG"
sed -i "s|worker.pid|$PIDFILE|g" $TMP_CONFIG

#read worker config file
_WORKER_CONFIG_FILE="/etc/pworker/worker.cfg"
read -p "Please select the worker config file name [$_WORKER_CONFIG_FILE] " WORKER_CONFIG_FILE
if [ -z "$WORKER_CONFIG_FILE" ] ; then
	WORKER_CONFIG_FILE=$_WORKER_CONFIG_FILE
	echo "Selected default - $WORKER_CONFIG_FILE"
fi
#try and create it
mkdir -p `dirname "$WORKER_CONFIG_FILE"` || die "Could not create worker config directory"
cp -f $TMP_CONFIG $WORKER_CONFIG_FILE || die "Could not copy configuration file"

#get worker data directory
_WORKER_DATA_DIR="/var/lib/pworker"
read -p "Please select the data directory for this instance [$_WORKER_DATA_DIR] " WORKER_DATA_DIR
if [ -z "$WORKER_DATA_DIR" ] ; then
	WORKER_DATA_DIR=$_WORKER_DATA_DIR
	echo "Selected default - $WORKER_DATA_DIR"
fi
mkdir -p $WORKER_DATA_DIR || die "Could not create worker data directory"
cp -rf "node" $WORKER_DATA_DIR"/node" || die "Could not copy node directory"

#read worker executable directory
_WORKER_EXE_DIR="/usr/bin"
read -p "Please select the worker executable directory [$_WORKER_EXE_DIR] " WORKER_EXE_DIR
if [ -z "$WORKER_EXE_DIR" ] ; then
	WORKER_EXE_DIR=$_WORKER_EXE_DIR
	echo "Selected default - $WORKER_EXE_DIR"
fi
mkdir -p $WORKER_EXE_DIR || die "Could not create worker executable directory"
cp -f "pworker" $WORKER_EXE_DIR || die "Could not copy executable file"
cp -f "prexec" $WORKER_EXE_DIR || die "Could not copy executable file"

#get worker executable path
WORKER_EXECUTABLE=`which pworker`
if [ ! -f "$WORKER_EXECUTABLE" ] ; then
	echo "Could not find worker executable"
	exit 1
fi

#get worker uid
_WORKER_USER=`whoami`
read -p "Please select the worker user name [$_WORKER_USER]" WORKER_USER
if [ -z "$WORKER_USER" ] ; then
	WORKER_USER=$_WORKER_USER
	echo "Selected default - $WORKER_USER"
fi
WORKER_UID=`id -u $WORKER_USER`

INIT_TPL_FILE="utils/worker_init_script.tpl"
INIT_SCRIPT_DEST="/etc/init.d/pworker"

WORKER_INIT_HEADER=\
"#/bin/sh\n
#Configurations injected by install_worker below....\n\n
EXEC=\"$WORKER_EXECUTABLE\"\n
RESOURCES=\"$WORKER_DATA_DIR\"\n
UID=$WORKER_UID\n
CONF=\"$WORKER_CONFIG_FILE\"\n\n
###############\n\n"

WORKER_CHKCONFIG_INFO=\
"# REDHAT chkconfig header\n\n
# chkconfig: - 58 74\n
# description: pworker is the prun worker daemon.\n
### BEGIN INIT INFO\n
# Provides: pworker\n
# Required-Start: $network $local_fs $remote_fs\n
# Required-Stop: $network $local_fs $remote_fs\n
# Default-Start: 2 3 4 5\n
# Default-Stop: 0 1 6\n
# Should-Start: $syslog $named\n
# Should-Stop: $syslog $named\n
# Short-Description: start and stop pmaster\n
# Description: Prun worker daemon\n
### END INIT INFO\n\n"

#Generate config file from the default config file as template
#changing only the stuff we're controlling from this script
echo "## Generated by install_worker.sh ##" > $TMP_CONFIG

if [ !`which chkconfig` ] ; then
	#combine the header and the template (which is actually a static footer)
	/bin/echo -e $WORKER_INIT_HEADER > $TMP_CONFIG && cat $INIT_TPL_FILE >> $TMP_CONFIG || die "Could not write init script to $TMP_CONFIG"
else
	#if we're a box with chkconfig on it we want to include info for chkconfig
	/bin/echo -e $WORKER_INIT_HEADER $WORKER_CHKCONFIG_INFO > $TMP_CONFIG && cat $INIT_TPL_FILE >> $TMP_CONFIG || die "Could not write init script to $TMP_CONFIG"
fi

#copy to /etc/init.d
cp -f $TMP_CONFIG $INIT_SCRIPT_DEST && chmod +x $INIT_SCRIPT_DEST || die "Could not copy worker init script to  $INIT_SCRIPT_DEST"
echo "Copied $TMP_CONFIG => $INIT_SCRIPT_DEST"

rm -f $TMP_CONFIG

#Install the service
echo "Installing service..."
if [ !`which chkconfig` ] ; then 
	#if we're not a chkconfig box assume we're able to use update-rc.d
	update-rc.d pworker defaults && echo "Success!"
else
	# we're chkconfig, so lets add to chkconfig and put in runlevel 345
	chkconfig --add pworker && echo "Successfully added to chkconfig!"
	chkconfig --level 345 pworker on && echo "Successfully added to runlevels 345!"
fi

/etc/init.d/pworker start || die "Failed starting service..."

echo "Installation successful!"
exit 0

