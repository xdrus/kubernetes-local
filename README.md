# README

## Prerequisites
### Install
* [Vagrant](https://www.vagrantup.com/)
* [VirtualBox](https://www.virtualbox.org/)
* [cfssl](https://github.com/cloudflare/cfssl)

### Create CA
Based on [kubernets the hard way manual](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md). All commands should be run in CA dir

* CA
```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

* Kuberenetes
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.100.100.10,127.0.0.1,master,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

* Admin
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

* Master
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=master,10.100.100.10,127.0.0.1 \
  -profile=kubernetes \
  master-csr.json | cfssljson -bare master
```

* Node
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=node-01,10.100.100.11 \
  -profile=kubernetes \
  node-01-csr.json | cfssljson -bare node-01
```

* Kube proxy
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

## Usage
### Run
```
vagrant up
```
Creates cluster with 2 VM (master/node) using kubenet plugin.

### Rerun provisioning scripts
```
vagrant up --provision
```

### Login
```
vagrant ssh master
```
OR
```
vagrant ssh node
```

### Tear down env
```
vagrant destroy
```
