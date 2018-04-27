Vagrant.configure("2") do |config|


  ########### Common configuration for masters and nodes
  config.vm.box = "bento/ubuntu-17.10"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = 1
    vb.memory = 2048
  end

  # install prerequsites
  config.vm.provision "shell", inline: <<-SHELL
    # Disable swap
    swapoff -a

    # Install docker-ce
    export DEBIAN_FRONTEND=noninteractive
    apt-get install --no-install-recommends -y \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable"
    apt-get update -y
    apt-get install --no-install-recommends -y docker-ce

    # Install CNI plugins
    export CNI_VERSION=v0.7.1
    wget -q --https-only --timestamping "https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-amd64-$CNI_VERSION.tgz"
    mkdir -p                     \
      /etc/cni/net.d             \
      /opt/cni/bin               \
      /etc/kubernetes/ca         \
      /etc/kubernetes/manifests
    tar -xvf cni-plugins-amd64-$CNI_VERSION.tgz -C /opt/cni/bin/

  SHELL

  # Env variables for shell scripts
  common_env = {
    "CONFIG_DIR"   => "/etc/kubernetes",
    "SERVICE_CIDR" => "10.100.101.0/24",
    "CLUSTER_DNS"  => "10.100.101.10",
    "ETCD_REGISTRY"=> "quay.io/coreos/etcd",
    "ETCD_VERSION" => "v3.2",
    "KUBE_RELEASE" => "v1.10.1",
    "CLUSTER"      => "kubenet-test",
    "MASTER_IP"    => "10.100.100.10",
    "NODE_IP"      => "10.100.100.11",
    "CLUSTER_CIDR" => "10.100.100.0/23"
  }

  master_env = {}
  master_env["POD_CIDR"] = "10.100.102.0/26"
  master_env.merge! common_env

  node_env = {}
  node_env["POD_CIDR"] = "10.100.102.64/26"
  node_env.merge! common_env


  # copy CA and kube-proxy certificates to temporary location
  config.vm.provision "file", source: "./ca/ca.pem", destination: "/var/tmp/kubernetes/ca/ca.pem"
  config.vm.provision "file", source: "./ca/ca-key.pem", destination: "/var/tmp/kubernetes/ca/ca-key.pem"
  config.vm.provision "file", source: "./ca/kube-proxy.pem", destination: "/var/tmp/kubernetes/ca/kube-proxy.pem"
  config.vm.provision "file", source: "./ca/kube-proxy-key.pem", destination: "/var/tmp/kubernetes/ca/kube-proxy-key.pem"


  ########### Configure master
  config.vm.define "master", primary: true  do |master|
    master.vm.provider "virtualbox" do |vb|
      vb.name  = "master"
    end
    master.vm.network "private_network", ip: "10.100.100.10", virtualbox__intnet: true
    master.vm.network "forwarded_port", guest: 443, host: 6443

    # Set hostname
    master.vm.hostname = "master"

    # copy kubelet certificate to temporary location
    master.vm.provision "file", source: "./ca/master.pem", destination: "/var/tmp/kubernetes/ca/kubelet.pem"
    master.vm.provision "file", source: "./ca/master-key.pem", destination: "/var/tmp/kubernetes/ca/kubelet-key.pem"

    # copy kuberenetes and etcd certificates to temporary location
    master.vm.provision "file", source: "./ca/kubernetes.pem", destination: "/var/tmp/kubernetes/ca/kubernetes.pem"
    master.vm.provision "file", source: "./ca/kubernetes-key.pem", destination: "/var/tmp/kubernetes/ca/kubernetes-key.pem"

    # Copy manifests for etcd and k8s CP components
    master.vm.provision "file", source: "./configs/manifests", destination: "/var/tmp/kubernetes/manifests"

    # Copy kubelet template to temporary location
    master.vm.provision "file", source: "./configs/kubelet.service", destination: "/var/tmp/kubernetes/kubelet.service"

    # Move files to a proper location (Vagrant doesn't allow copy files directly to '/etc/')
    master.vm.provision "shell", path: "./scripts/move_files.sh"

    # Configure manifests
    master.vm.provision "shell", path: "./scripts/configure_manifests.sh", env: master_env

    # Configure and run kubelet
    master.vm.provision "shell", path: "./scripts/configure_kubelet.sh", env: master_env

    # Add route
    master.vm.provision "shell", inline: <<-SHELL
      route add -net #{node_env['POD_CIDR']} gw 10.100.100.11 dev eth1
      iptables -I FORWARD -s #{node_env['POD_CIDR']} -j ACCEPT
      iptables -I FORWARD -d #{node_env['POD_CIDR']} -j ACCEPT
    SHELL
  end

  ########### Configure node
  config.vm.define "node" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name  = "node"
    end
    node.vm.network "private_network", ip: "10.100.100.11", virtualbox__intnet: true

    # Set hostname
    node.vm.hostname = "node-01"

    # copy kubelet certificate to temporary location
    node.vm.provision "file", source: "./ca/node-01.pem", destination: "/var/tmp/kubernetes/ca/kubelet.pem"
    node.vm.provision "file", source: "./ca/node-01-key.pem", destination: "/var/tmp/kubernetes/ca/kubelet-key.pem"

    # Copy manifests for kube-proxy
    node.vm.provision "file", source: "./configs/manifests/kube-proxy.yaml", destination: "/var/tmp/kubernetes/manifests/kube-proxy.yaml"

    # Copy kubelet template to temporary location
    node.vm.provision "file", source: "./configs/kubelet.service", destination: "/var/tmp/kubernetes/kubelet.service"

    # Move files to a proper location (Vagrant doesn't allow copy files directly to '/etc/')
    node.vm.provision "shell", path: "./scripts/move_files.sh"

    # Configure manifests
    node.vm.provision "shell", path: "./scripts/configure_manifests.sh", env: node_env

    # Configure and run kubelet
    node.vm.provision "shell", path: "./scripts/configure_kubelet.sh", env: node_env

    # Add route
    node.vm.provision "shell", inline: <<-SHELL
      route add -net #{master_env['POD_CIDR']} gw 10.100.100.10 dev eth1
      iptables -I FORWARD -s #{node_env['POD_CIDR']} -j ACCEPT
      iptables -I FORWARD -d #{node_env['POD_CIDR']} -j ACCEPT
    SHELL
  end
end
