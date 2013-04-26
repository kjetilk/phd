#!/bin/bash

killall 4s-backend 
killall 4s-httpd
cd 4store-unmodified/
bin/4s-backend largeunmod
bin/4s-httpd -s -1 -p 8012 largeunmod
bin/4s-backend smallunmod
bin/4s-httpd -s -1 -p 8011 smallunmod
cd ../4store-sleep/
bin/4s-backend largesleep
bin/4s-backend smallsleep
bin/4s-httpd -s -1 -p 8022 largesleep
bin/4s-httpd -s -1 -p 8021 smallsleep
ps ux | grep 4s

echo 8012
wget -O /dev/null http://localhost:8012/status/
echo 8011
wget -O /dev/null http://localhost:8011/status/
echo 8022
wget -O /dev/null http://localhost:8022/status/
echo 8021
wget -O /dev/null http://localhost:8021/status/

exit 0