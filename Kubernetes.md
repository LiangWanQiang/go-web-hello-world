## Kubernetes and Kubernetes Dashboard

[TOC]

### Task 9: Install a single node Kubernetes cluster using kubeadm

Refer to https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/ to install kubernetes.

By default, your cluster will not schedule Pods on the control-plane node for security reasons. If you want to be able to schedule Pods on the control-plane node, for example for a single-machine Kubernetes cluster for development, run:

```
$ kubectl taint nodes --all node-role.kubernetes.io/master-
```

### Task 10: Deploy the hello world container

Deploy `go-web-hello-world` in the kubernetes and expose the service to nodePort 31080.

The deploy procedure is as below.

```
$ kubectl create deployment go-web-hello-world --image=liangwq/go-web-hello-world:v0.1
deployment.apps/go-web-hello-world created

$ kubectl expose deployment go-web-hello-world --port=8081 --type=NodePort
service/go-web-hello-world exposed

$ kubectl patch svc go-web-hello-world \
> -p '{"spec":{"type":"NodePort","ports":[{"port":8081,"targetPort":8081,"nodePort":31080}]}}'

$ kubectl get pods,svc,endpoints
NAME                                      READY   STATUS    RESTARTS   AGE
pod/go-web-hello-world-666dcf6bd9-xf6g6   1/1     Running   0          46m

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/go-web-hello-world   NodePort    10.96.85.232    <none>        8081:31080/TCP   4m1s
service/kubernetes           ClusterIP   10.96.0.1       <none>        443/TCP          65m

NAME                           ENDPOINTS            AGE
endpoints/go-web-hello-world   10.244.0.4:8081      4m1s
endpoints/kubernetes           172.31.81.232:6443   65m

$ curl http://localhost:31080
Go Web Hello World!
```

![image-20210307132948994](images/image-20210307132948994.png?raw=true)

### Task 11: Install kubernetes dashboard

Install kubernetes dashboard and expose the service to nodePort 31081.

The procedure is as below.

```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created

$ kubectl  patch svc kubernetes-dashboard -n kubernetes-dashboard \
> -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8443,"nodePort":31081}]}}'
service/kubernetes-dashboard patched

[root@wqcentos2 ~]# kubectl get pods,svc,endpoints -n kubernetes-dashboard
NAME                                             READY   STATUS    RESTARTS   AGE
pod/dashboard-metrics-scraper-6b4884c9d5-gf9pz   1/1     Running   0          8m31s
pod/kubernetes-dashboard-7b544877d5-8vm6r        1/1     Running   0          8m31s

NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
service/dashboard-metrics-scraper   ClusterIP   10.109.212.15   <none>        8000/TCP        8m31s
service/kubernetes-dashboard        NodePort    10.101.183.70   <none>        443:31081/TCP   8m31s

NAME                                  ENDPOINTS          AGE
endpoints/dashboard-metrics-scraper   10.244.0.10:8000   8m31s
endpoints/kubernetes-dashboard        10.244.0.9:8443    8m31s

[root@wqcentos2 ~]# curl https://localhost:31081
curl: (60) Issuer certificate is invalid.
More details here: http://curl.haxx.se/docs/sslcerts.html

curl performs SSL certificate verification by default, using a "bundle"
of Certificate Authority (CA) public keys (CA certs). If the default
bundle file isn't adequate, you can specify an alternate file
using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
the bundle, the certificate verification probably failed due to a
problem with the certificate (it might be expired, or the name might
not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
the -k (or --insecure) option.
```

### Task 12: Generate token for dashboard login in task 11

Create `dashboard-adminuser.yaml` to create admin account.

```
$ cat > dashboard-adminuser.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard  
EOF
```

Create admin account.

```
$ kubectl apply -f dashboard-adminuser.yaml
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```

Generate token.

```
$ kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
Name:         admin-user-token-xr9qq
Namespace:    kubernetes-dashboard
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: e09ab464-c9da-4235-91f1-14eb4f0ab164

Type:  kubernetes.io/service-account-token

Data
====
namespace:  20 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IjUtbzh2d2lzZUVOdXM3WldCQktVVDNzLXZDdFNCRlRxNDBfWVE5bThpTTgifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXhyOXFxIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJlMDlhYjQ2NC1jOWRhLTQyMzUtOTFmMS0xNGViNGYwYWIxNjQiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.MOvOpFxVyotE-jgNadO9lh7CEvX50bLrcuDeukwssxjsNzE7e42EUIQgD_fEYawK4DjkAgwn3P0cXYUIZaymAnPAmFEP2lqqiRUfTg5AkNw9q1NEYC-lwRQxNKjF_Xze1TlL1hXAWiXc6H5YarjxjNILjpkpGi_xQ10Y845J9dclDcXwTZGSKgE3iEZLKo7TBuzOtD7iK_n496a_UoqGKKl7jlga2Qh_VsxbusvGtJzeoD_hweQYRxDZTXpE0WXsBiGidfMW_QXpkko92Jl_1mq0RQLUcA-vTeNRv-U6y1q83-egdMyb_td0rkKhFF7yoiHDv0p9V0SlUnedz0BIfg
ca.crt:     1025 bytes
[root@wqcentos2 ~]#
```

Using the generated token to login kubernetes dashboard. 

![image-20210307200551486](images/image-20210307200551486.png?raw=true)

![image-20210307132809300](images/image-20210307132809300.png?raw=true)

