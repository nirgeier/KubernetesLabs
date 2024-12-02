# Remove old chart if its already exists
helm uninstall codewizard-helm-demo
sleep 10

# Pack the Helm in the desired folder
helm package codewizard-helm-demo

# install the helm and view the output
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz 

sleep 10
# verify that the chart installed
kubectl get all -n codewizard

# Check the response from the chart
kubectl delete pod busybox --force --grace-period=0 2&>/dev/null
kubectl run busybox             \
            --image=busybox     \
            --rm                \
            -it                 \
            --restart=Never     \
            -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local"
