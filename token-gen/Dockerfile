FROM alpine
RUN apk update
RUN apk add --no-cache curl
RUN RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)" && \
    mkdir -p /opt/bin && cd /opt/bin && \
    curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/kubeadm && \
    chmod +x kubeadm

ENTRYPOINT /opt/bin/kubeadm token generate
