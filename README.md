Continuous Integration automated site build for Drupal
======================================================

Introduction
-----------
This image allows a container to be created for automatically building adn testing for Drupal websites, removetyl controlled  from jenkins.

Installation
---------------
 - Setup the cibuild container (see https://github.com/Boran/docker-cibuild), it will have all Drupal prerequisites and passwords in files such as /drupal-admin-pw.txt /mysql-drupal-pw.txt /mysql-root-pw.txt
 - create /home/builder and checkout this repo into /home/builder/drupal-ci
 - add /home/builder/.netrc with git credentials if needed for your git repo. Secure the file with permissions 400.```
machine git.example.ch
login my-jenkins-user
password mySecret```

 - Optional: Add sample DB, files, tests to /home/builder/source-....
 - Optional: Edit playbooks/settings.yml and create playbooks/build/PROJECT-test-site-build.yml
 - test a build on the command line, then test from Jenkins (see below)


Running Drupal profile install
------------------------------
Now build on the command line (e.g. branch=develop build=2 for project1, standard profile)
```
su - jenkins
sudo /home/builder/drupal-ci/site-build.sh develop 2 project1 https://git.example.ch/git/user-website.git standard

# prof1 profile
sudo /home/builder/drupal-ci/site-build.sh develop 2 project1 https://git.example.ch/git/user-website.git prof1

# +expect included tests and do a feature revert
sudo /home/builder/drupal-ci/site-build.sh develop 2 project1 https://git.example.ch/git/user-website.git prof1 n y

# Call build from a jenkins job
ssh -p 2201 jenkins@cibuild.webfact.example.ch "SUDO_LINE_AS_ABOVE"
```



Running with Demo data
-----------------------
Sample data
  source-dbs/PROJECT/xx.mysql.gz
  source-files/PROJECT/xx.tar.gz
  source-other: tests, if the option to include default tests is enabled. 

```
# +default tests and do a feature revert
sudo /home/builder/drupal-ci/site-build.sh develop 2 project1 https://git.example.ch/git/website.git standard y y
```
## Thanks ##
To webscope.co.nz who provided the original code that was then rewritten for docker env runing the boran/cibuild image.


