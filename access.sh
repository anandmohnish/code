#!/bin/bash
apt-get update
apt-get install apache2 -y
sudo apt-get install gcc -y                       
cd /root
wget http://download.redis.io/redis-stable.tar.gz 
tar xvzf redis-stable.tar.gz                      
cd redis-stable                                   
sudo apt-get install make -y                      
make distclean
make                                    
