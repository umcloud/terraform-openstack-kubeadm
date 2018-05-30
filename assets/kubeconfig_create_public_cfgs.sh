#!/bin/sh
mkdir -p ~/public
kubectl config view -o json --flatten | jq -r '.clusters[]|select(.name="kubernetes")|.cluster["certificate-authority-data"]'  | base64 -d > ~/public/kubernetes-ca.crt
server=$(kubectl config view -o json --flatten | jq -r '.clusters[]|select(.name="kubernetes")|.cluster["server"]')

cat > ~/public/kubernetes-init.sh << EOF
#!/bin/sh
echo "# You run ->"
echo kubectl config set-cluster --certificate-authority=$HOME/public/kubernetes-ca.crt --server ${server:?} kubernetes
echo kubectl config set-context --cluster=kubernetes --user=\${USER} --namespace=\${USER} \${USER}
echo kubectl config set-credentials \${USER} --token YOUR_GITHUB_TOKEN
echo kubectl config use-context \${USER}
echo kubectl config view
EOF
chmod +x ~/public/kubernetes-init.sh

