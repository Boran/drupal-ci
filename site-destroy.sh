#!/bin/bash -x

GIT_BRANCH=$1
BUILDID=$2
SITEURL=$3

echo "DESTROYING! Git branch : $GIT_BRANCH with job id : $BUILDID for site : $SITEURL"

cd /home/builder/drupal-ci

#pwd

# Let's make this project specific
ansible-playbook playbooks/destroy/test-site-destroy.yml --extra-vars "git_branch=$GIT_BRANCH build_id=$BUILDID url_prefix=$SITEURL"
