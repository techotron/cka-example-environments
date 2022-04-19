#!/bin/sh
apt-get update

cp /vagrant/certs/id_rsa /root/.ssh/id_rsa
cp /vagrant/certs/id_rsa.pub /root/.ssh/id_rsa.pub
chmod 400 /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa.pub
