#!/bin/bash

sudo apt-get update && sudo apt-get -y install apache2


echo '<!doctype html><html><body><h1>Hello, Happy New Year Everyone!</h1></body></html>' | sudo tee /var/www/html/index.html

sudo systemctl restart apache2
sudo systemctl enable apache2
