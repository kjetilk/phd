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
exit 0