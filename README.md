# GCP GKE test cluster

Templates for building a GKE cluster for developing and testing
kubernetes operators.


## Create a cluster

Copy over `envrc.example` to `.envrc` and
edit to suit your environment.  Then source this file:
```bash
source .envrc
```

Copy over `terraform/backend.conf.example` to `terraform/backend.conf` and
edit to suit your environment.

Next, spin up resources in this order:

### network

```bash
cd terraform/network
terraform init -backend-config ../backend.conf
terraform plan
terraform apply
```

### jumpbox

```bash
cd ../jumpbox
terraform init -backend-config ../backend.conf
terraform plan
terraform apply
```

### gke-cluster

```bash
cd ../gke-cluster
terraform init -backend-config ../backend.conf
terraform plan
terraform apply
```

Note: go get coffee... this apply can take around 15-20mins.


## Access the cluster

### Work _from_ the jumpbox

Access the jumpbox:
```bash
gcloud compute ssh jumpbox-0 --zone us-central1-c
```

From the jumpbox, get cluster credentials:
```bash
gcloud container clusters get-credentials scheduling-ops --region us-central1
```

From the jumpbox, run `kubectl` commands normally:
```bash
kubectl get nodes
```


### Work _through_ the jumpbox

From your development workstation, get cluster credentials:
```bash
gcloud container clusters get-credentials scheduling-ops --region us-central1
```

From your development workstation, edit your local `~/.kube/config` to change
the "server" entry from something like `https://10.13.0.2` to
`https://localhost:8443`. Your api server will likely have a different IP
address than what I show here.

Set up port forwarding through the jumpbox (using a separate terminal window):
```bash
gcloud compute ssh jumpbox-0 --zone us-central1-c -- -L8443:10.13.0.2:443
```
where `10.13.0.2` is the ip address of your k8s api "server" from the
`.kube/config` file you edited above.

Note: we're knowingly breaking TLS certs for development in this version of the
workflow, so run subsequent `kubectl` commands using the
`--insecure-skip-tls-verify` flag:
```bash
kubectl --insecure-skip-tls-verify get ns
```


## Test out basic connectivity within the cluster

No matter your access method, test out the following:


### A deployment

Create a file `nginx-deployment.yaml' with the following:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx-container
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```
and then instantiate this:
```
kubectl apply -f nginx-deployment.yaml
```

You can watch progress with
```
kubectl get deployments
```
(Remember to add the `--insecure-skip-tls-verify` flag if you're jumping
_through_ the jumpbox).


### A service

Create a file `nginx-svc.yaml` with the following:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
```
and then instantiate this:
```
kubectl apply -f nginx-svc.yaml
```

You can watch progress with
```
kubectl get svc
```


### A debug pod

and of course the ubiquitous debug-pod.yaml:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: default
spec:
  containers:
  - name: debug-container
    image: debian:bookworm
    command: ["/bin/sleep"]  # Sleep command to keep the container running
    args: ["infinity"]  # Sleep indefinitely to prevent the container from exiting
```
which you can access using `kubectl exec -it debug-pod -- bash`.

Once in the debug pod, you can do things like
```
curl http://nginx.default.svc.cluster.local
```
to check the service and deployment you created above.




