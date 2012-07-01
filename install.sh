#!/bin/sh

# Install script for brat server
#
# Author:   Sampo Pyysalo       <smp is s u tokyo ac jp>
# Author:   Pontus Stenetorp    <pontus is s u tokyo ac jp>
# Version:  2012-02-09

# defaults

WORK_DIR=work
DATA_DIR=data
CONFIG_TEMPLATE=config_template.py
CONFIG=config.py

# Absolute data and work paths

base_dir=`(cd \`dirname $0\`; pwd)`

work_dir_abs="$base_dir/$WORK_DIR"
data_dir_abs="$base_dir/$DATA_DIR"

# Ask details for config

while true; do
    echo "Please enter a brat username"
    read user_name
    if [ -n "$user_name" ]; then
	break
    fi
done

while true; do
    echo "Please enter a brat password (this shows on screen)"
    read password
    if [ -n "$password" ]; then
	break
    fi
done

echo "Please enter the administrator contact email"
read admin_email

# Put a configuration in place.

(echo '# This is configuration was automatically generated by '`basename $0`
cat "$base_dir/$CONFIG_TEMPLATE" | sed \
    -e '1s/\(.*\)/from os.path import dirname, join as path_join\n\1/' \
    -e 's|\(ADMIN_CONTACT_EMAIL = \).*|\1'\'$admin_email\''|' \
    -e "s|\(BASE_DIR = \).*|\1dirname(__file__)|" \
    -e "s|\(DATA_DIR = \).*|\1path_join(BASE_DIR, '${DATA_DIR}')|" \
    -e "s|\(WORK_DIR = \).*|\1path_join(BASE_DIR, '${WORK_DIR}')|" \
    -e '/\(USER_PASSWORD *= *{.*\)/a\
        \    '\'"$user_name"\'': '\'"$password"\'',') > "$base_dir/$CONFIG"

# Create directories

mkdir -p $work_dir_abs
mkdir -p $data_dir_abs

# Try to determine apache group

apache_user=`ps aux | grep '[a]pache\|[h]ttpd' | cut -d ' ' -f 1 | grep -v '^root$' | head -n 1`
apache_group=`groups $apache_user | head -n 1 | sed 's/ .*//'`

# Make $work_dir_abs and $data_dir_abs writable by apache

group_ok=0
if [ -n "$apache_group" -a -n "$apache_user" ] ; then
    echo "Assigning owner of the following directories to apache ($apache_group):"
    echo "    \"$work_dir_abs/\""
    echo "and"
    echo "    \"$data_dir_abs/\""
    echo "(this requires sudo; please enter your password if prompted)"

    sudo chgrp -R $apache_group $data_dir_abs $work_dir_abs
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
	chmod -R g+rwx $data_dir_abs $work_dir_abs
	group_ok=1
    else
	echo "WARNING: failed to change group."
    fi
else
    echo "WARNING: failed to determine apache group."
fi

if [ $group_ok -eq 0 ]; then
    echo
    echo "Setting global read and write permissions to directories\n    \"$work_dir_abs/\" and\n    \"$data_dir_abs/\""
    echo "(you may wish to consider fixing this manually)"
    chmod -R 777 $data_dir_abs $work_dir_abs
fi

# Extract the most important library dependencies.

( cd server/lib && tar xfz simplejson-2.1.5.tar.gz )

# Dump some last instructions to the user
echo 'The installation has finished, you are almost done.'
echo
echo '1.) Please verify that brat is running by accessing your installation'
echo '    using a web browser.'
echo
echo 'You can automatically diagnose some common installation issues using:'
echo
echo '    tools/troubleshooting.sh URL_TO_BRAT_INSTALLATION'
echo
echo 'If there are issues not detected by the above script, please contact the'
echo 'brat developers and/or file a bug to the brat bug tracker:'
echo
echo '    https://github.com/nlplab/brat/issues'
echo
echo '2.) Once brat is running, put your data in the data directory:'
echo
echo "    ${data_dir_abs}"
echo
echo '3.) You can find configuration files to place in your data directory in'
echo '    the configurations directory, see the manual for further details:'
echo
echo "    ${base_dir}/configurations"
echo
echo '4.) Then, you (and your team?) are ready to start annotating!'
