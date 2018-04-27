#!/bin/sh

set -ex

mv /var/tmp/kubernetes/kubelet.service /etc/systemd/system/kubelet.service

mkdir -p /etc/kubernetes
cp -r /var/tmp/kubernetes/* /etc/kubernetes/
