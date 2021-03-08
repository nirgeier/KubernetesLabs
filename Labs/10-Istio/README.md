![](../../resources/k8s-logos.png)

---

# Istio

## Pre-Requirements 
- K8S cluster (or minikube)

## Follow these steps to get started with Istio:

1. Download and install Istio
2. Deploy the sample application
3. Open the application to outside traffic
4. View the dashboard

### 1. Download latest Istio release (Linux)
```sh
curl -L https://istio.io/downloadIstio | sh -

# Navigate to the istio folder
# The installation directory contains:
# Sample applications in samples/
# The istioctl client binary in the bin/ directory.
```
### 1.1 Add the istioctl client to your path (Linux or macOS):
```
$ export PATH=$PWD/bin:$PATH
```

### 1.2 Install Istio
```sh
# For this installation, we use the demo configuration profile
$ istioctl install --set profile=demo -y

# The output should be something like
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete
```

### 1.3 Install Istio
- Add a namespace label to instruct Istio to **automatically inject Envoy sidecar** proxies when you deploy your application later:
```
$ kubectl label namespace default istio-injection=enabled
namespace/default labeled
```

### 2. Deploy the sample application
- Deploy the Bookinfo sample application:
```sh
# Navigate to the istio download folder
$cd istio-xxx

# Deploy the sample application
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Output
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
```

### 2.1 Check the installation
- The application will start. 
- As each pod becomes ready, the Istio sidecar will be deployed along with it.
```
$ kubectl get all
NAME                                  READY   STATUS   
pod/details-v1-79c697d759-vwqdw       2/2     Running   
pod/productpage-v1-65576bb7bf-w2gpr   2/2     Running   
pod/ratings-v1-7d99676f7f-krwk9       2/2     Running   
pod/reviews-v1-987d495c-ltxvx         2/2     Running   
pod/reviews-v2-6c5bf657cf-r74lq       2/2     Running   
pod/reviews-v3-5f7b9f4f77-qgtn5       2/2     Running 

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    
service/details       ClusterIP   10.109.142.110   <none>        9080/TCP   
service/kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP    
service/productpage   ClusterIP   10.106.91.75     <none>        9080/TCP   
service/ratings       ClusterIP   10.106.35.0      <none>        9080/TCP   
service/reviews       ClusterIP   10.99.208.202    <none>        9080/TCP   

NAME                             READY   UP-TO-DATE   AVAILABLE   
deployment.apps/details-v1       1/1     1            1           
deployment.apps/productpage-v1   1/1     1            1           
deployment.apps/ratings-v1       1/1     1            1           
deployment.apps/reviews-v1       1/1     1            1           
deployment.apps/reviews-v2       1/1     1            1           
deployment.apps/reviews-v3       1/1     1            1           

NAME                                        DESIRED   CURRENT   READY   
replicaset.apps/details-v1-79c697d759       1         1         1       
replicaset.apps/productpage-v1-65576bb7bf   1         1         1       
replicaset.apps/ratings-v1-7d99676f7f       1         1         1       
replicaset.apps/reviews-v1-987d495c         1         1         1       
replicaset.apps/reviews-v2-6c5bf657cf       1         1         1       
replicaset.apps/reviews-v3-5f7b9f4f77       1         1         1       
```

### 2.2 Verify that Istio is working
- Run this command to see if the app is running inside the cluster and serving HTML pages by checking for the page title in the response:
```sh
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
        -c ratings \
        -- curl \
        -s productpage:9080/productpage \
        | grep -o "<title>.*</title>"
```        

---

<div align="center">  
    <img src="../../resources/prev.png"><img src="../../resources/prev.png"><img src="../../resources/prev.png">&nbsp;
    <a href="../09-StatefulSet">09-StatefulSet</a>
    &nbsp;&nbsp;||&nbsp;&nbsp;
    <a href="../11-CRD-Custom-Resource-Definition">11-CRD-Custom-Resource-Definition</a>
    &nbsp;<img src="../../resources/next.png"><img src="../../resources/next.png"><img src="../../resources/next.png">
    <br/>
</div>

---

<div align="center">  
    <small>&copy;CodeWizard LTD</small>
</div>