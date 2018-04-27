#!/bin/sh

set -ex

INTERNAL_IP=$(ifconfig eth1 | awk '/net / {print $2}')

sed -i "s|{{CLUSTER_DNS}}|$CLUSTER_DNS|g" /etc/systemd/system/kubelet.service
sed -i "s|{{CONFIG_DIR}}|$CONFIG_DIR|g" /etc/systemd/system/kubelet.service
sed -i "s|{{KUBE_RELEASE}}|$KUBE_RELEASE|g" /etc/systemd/system/kubelet.service
sed -i "s|{{INTERNAL_IP}}|$INTERNAL_IP|g" /etc/systemd/system/kubelet.service
sed -i "s|{{POD_CIDR}}|$POD_CIDR|g" /etc/systemd/system/kubelet.service
sed -i "s|{{CLUSTER_CIDR}}|$CLUSTER_CIDR|g" /etc/systemd/system/kubelet.service


alias kubectl="docker run --rm --net=host -v /etc/kubernetes/:/etc/kubernetes/ k8s.gcr.io/hyperkube:$KUBE_RELEASE kubectl "

kubectl config set-cluster $CLUSTER \
  --certificate-authority=/etc/kubernetes/ca/ca.pem \
  --embed-certs=true \
  --server=https://$MASTER_IP:6443 \
  --kubeconfig=/etc/kubernetes/kubeconfig

kubectl config set-credentials system:node:$INTERNAL_IP \
  --client-certificate=/etc/kubernetes/ca/kubelet.pem \
  --client-key=/etc/kubernetes/ca/kubelet-key.pem \
  --embed-certs=true \
  --kubeconfig=/etc/kubernetes/kubeconfig

kubectl config set-context default \
  --cluster=$CLUSTER \
  --user=system:node:$INTERNAL_IP \
  --kubeconfig=/etc/kubernetes/kubeconfig

kubectl config use-context default --kubeconfig=/etc/kubernetes/kubeconfig

echo "Creating interface cbr0"
ip link show cbr0
if [ $? -ne 0 ];
then
  iptables -t nat -F
  ip link add cbr0 type bridge
  ip addr add $POD_CIDR dev cbr0
  ip link set cbr0 up
fi

cat > /etc/docker/daemon.json <<EOF
{
 "bridge": "cbr0",
 "ip-masq": false,
 "iptables": false
}
EOF
sysctl -w net.ipv4.ip_forward=1

# Start docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker


# start kubelet
systemctl enable kubelet
systemctl start kubelet
