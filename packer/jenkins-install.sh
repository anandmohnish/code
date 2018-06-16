#The below script install jenkins and required dependencies.
#Reference - https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-16-04
#Reference - https://wiki.jenkins.io/display/JENKINS/Installing+Jenkins+on+Ubuntu
#!/bin/bash 
set -e
set -v

apt-get update
apt-get upgrade -y

#Install wget
apt-get install -y wget
apt-get install -y apt-transport-https
apt-get install -y ufw

#Install Jenkins
#Add repo key
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
#Add repo address to source.list
echo deb https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list

# Get new repo's
apt-get update

#Install Jenkins
apt-get install -y jenkins
apt-get install openjdk-8-jdk
service jenkins start 
