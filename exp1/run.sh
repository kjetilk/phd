#!/bin/bash

killall 4s-backend 
killall 4s-httpd
cd 4store-unmodified/
bin/4s-backend largeunmod
bin/4s-httpd -s -1 -p 8022 largeunmod
bin/4s-backend smallunmod
bin/4s-httpd -s -1 -p 8021 smallunmod
cd ../4store-sleep/
bin/4s-backend largesleep
bin/4s-backend smallsleep
bin/4s-httpd -s -1 -p 8012 largesleep
bin/4s-httpd -s -1 -p 8011 smallsleep
ps ux | grep 4s

curl -s -o /dev/null -w "%{url_effective} %{http_code}\n" http://localhost:8011/status/

curl -s -o /dev/null -w "%{url_effective} %{http_code}\n" http://localhost:8012/status/

curl -s -o /dev/null -w "%{url_effective} %{http_code}\n" http://localhost:8021/status/

curl -s -o /dev/null -w "%{url_effective} %{http_code}\n" http://localhost:8022/status/

exit 0