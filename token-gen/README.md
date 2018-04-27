# Docker Image of Kubeadm to Generate Tokens
The terraform process in this package requires that the operator provide a
kubeadm token that is passed to both the master and the workers to enable them
to find each other and register. The Kubeadm program has a feature to create
random tokens.

This dockerfile encapsulates kubeadm and its entrypoint simply calls kubeadm
with the correct arguments to generate a token.

## To Generate a Token
Just build the docker image:
```bash
% docker build -t token-gen .
```

and then run the image to get a token:
```bash
% docker run token-gen
```

This will output a kubeadm token that you can paste into your console when
terraform apply is looking for a value for `${var.token}`
