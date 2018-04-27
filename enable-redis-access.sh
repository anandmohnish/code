#Execute chmod 755 enable-redis-access.sh
#Run the script by typing sh enable-redis-access.sh
# Author: Mohnish Anand

#!/bin/bash
#Stop executing if error occurs
set -e
#Verbose output
#set -v

sudo yum install gcc
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
#make distclean  // Ubuntu systems only
make
src/redis-cli -c -h mycachecluster.eaogs8.0001.usw2.cache.amazonaws.com -p 6379
