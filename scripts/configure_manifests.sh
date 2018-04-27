#!/bin/sh

set -ex

INTERNAL_IP=$(ifconfig eth1 | awk '/net / {print $2}')


sed -i "s|{{CLUSTER_DNS}}|$CLUSTER_DNS|g" /etc/kubernetes/manifests/*
sed -i "s|{{CONFIG_DIR}}|$CONFIG_DIR|g" /etc/kubernetes/manifests/*
sed -i "s|{{KUBE_RELEASE}}|$KUBE_RELEASE|g" /etc/kubernetes/manifests/*
sed -i "s|{{INTERNAL_IP}}|$INTERNAL_IP|g" /etc/kubernetes/manifests/*
sed -i "s|{{POD_CIDR}}|$POD_CIDR|g" /etc/kubernetes/manifests/*
sed -i "s|{{ETCD_REGISTRY}}|$ETCD_REGISTRY|g" /etc/kubernetes/manifests/*
sed -i "s|{{ETCD_VERSION}}|$ETCD_VERSION|g" /etc/kubernetes/manifests/*
sed -i "s|{{CLUSTER_CIDR}}|$CLUSTER_CIDR|g" /etc/kubernetes/manifests/*
sed -i "s|{{SERVICE_CIDR}}|$SERVICE_CIDR|g" /etc/kubernetes/manifests/*
