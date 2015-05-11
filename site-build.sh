#!/bin/bash
#set -x

# site-build.sh
# This gets called from Jenkins as a shell script that gets executed when a build is triggered.
# e.g ssh jenkins@BUILD_SERVER "sudo /home/builder/drupal-ci/site-build.sh develop 37 project1 https://git.example/git/user-website.git y"
# Arguments
#   1 = GIT_BRANCH
#   2 = build number incrmental
#   3 = SITENAME  Name to identify the project
#   4 = Git URL to pull code from
#   5 = y/n - look for demo DB/files; or drupal install profile
#   6 = y/n - copy sample tests into the site   (default n)
#   7 = y/n - do a drupal feature revert   (default n)
#
#   The URL will be http://webserver_hostname/$SITENAME-$GIT_BRANCH-build-$BUILDID
#   e.g.
#   http://cibuild.webfact.corproot.net/project1-develop-build-25
#
# see also ./playbooks/settings.yml and ansible templates
# Set drupal default pws: /drupal-admin-pw.txt /mysql-drupal-pw.txt

GIT_BRANCH=$1

BUILDID=$2
SITENAME=$3
GIT_REPO=$4

#todo: exit if arguments 1-4 missing
if [ -z "$5" ] ; then  # is demo db/files to be used?
   # no $5: no demo db, and no profile
   DEMO="n";
   drupal_profile='';
else
   if [ "$5" == "y" ] ; then
     DEMO="y"
     drupal_profile=''
   else
     # install profile name
     DEMO="n"
     drupal_profile=$5
   fi
fi

# by default no tests are copied into the build and features are not reverted
local_tests='n'
revert_features='n'
if [ ! -z "$6" ] ; then
  local_tests=$6;
fi;
if [ ! -z "$7" ] ; then
  revert_features=$7;
fi;


www="/var/www/html"
buildserver=`hostname`;
buildhome="/home/builder"
localsrc="$buildhome"
builddir="$buildhome/drupal-ci"   # run this script from here
cd $builddir || exit -1

ansible="ansible-playbook "       # debugging: --verbose

# Drupal settings
drupal_admin_email='drupalci@example.ch';
if [ -r /drupal-admin-pw.txt ] ; then
  drupal_admin_pw=`cat /drupal-admin-pw.txt`;
else
  echo "Drupal admin pasword in /drupal-admin-pw.txt not found";
  exit 1;
fi
if [ -r /mysql-drupal-pw.txt ] ; then
  mysql_password=`cat /mysql-drupal-pw.txt`;
else
  echo "Drupal mysql /mysql-drupal-pw.txt not found";
  exit 1;
fi


# Following settings, used by ansible, were in playbooks/build/generic.yml,
# move here for consistency
#fullname="$SITENAME-$GIT_BRANCH-build-$BUILDID";
# Srip special characters from branch name
branch=`echo $GIT_BRANCH|tr '\/' '-' `
fullname="$SITENAME-$branch-build-$BUILDID";

sitepath="$www/$fullname";
site_data_path="$buildhome/site-data/$fullname";
# db will be fullname with underscores (may not have dashes: mysql)
db_name=`echo $fullname|tr '-' '_' `


echo "--------------------------------------------------------"
echo "-- $0: Build $SITENAME from branch=$GIT_BRANCH $GIT_REPO with id=$BUILDID demo=$DEMO drupal_profile=$drupal_profile local_tests=$local_tests revert_features=$revert_features builddir=$builddir fullname=$fullname db_name=$db_name."

echo "-- ansible: init, database, files, test, finalise:"

extravars="webserver_hostname=$buildserver git_branch=$GIT_BRANCH build_id=$BUILDID url_prefix=$SITENAME localsrc=$localsrc git_repo=$GIT_REPO localdb_enable=$DEMO drupal_profile=$drupal_profile revert_features=$revert_features local_tests=$local_tests sitename=$fullname sitepath=$sitepath site_data_path=site_data_path db_name=$db_name drupal_admin_pw=$drupal_admin_pw drupal_admin_email=$drupal_admin_email mysql_password=$mysql_password"

#echo "$ansible playbooks/build/generic.yml --extra-vars $extravars"
$ansible playbooks/build/generic.yml --extra-vars "$extravars"  || exit -1

echo "-- /ansible done ---- "
echo "  "

echo "-- Looking for app buildscript in /env_scripts"
if [ -f $www/$fullname/env_scripts/build_ci.sh ] ; then
  echo "-- Run $www/$fullname/env_scripts/build_ci.sh"
  echo "-- script contents:"
  cat $www/$fullname/env_scripts/build_ci.sh
  echo "-- end script, now running it:"
  cd $www/$fullname/env_scripts/ && sh ./build_ci.sh
fi

echo "-- Run tests "
testdir=$fullname/tests
cd $www/$testdir  || exit -1

# Generate human readable acceptance tests in folder {{ webroot}}/tests/tests/_data/scenarios/acceptance
#echo "-- Generating acceptance tests docs"
#codecept g:scenarios acceptance --format html

echo "-- Generate scenarios in text format"
codecept g:scenarios acceptance --format text
echo "  "
echo "-- See results on http://$buildserver/$testdir and http://$buildserver/$testdir/tests/_log/report.html"
echo "  "

# IMPORTANT This always needs to be the last command executed
# so that Jenkins can read the exit status to determine a pass or fail
echo "-- Running acceptance tests"
#codecept run acceptance --steps
codecept run acceptance --html
