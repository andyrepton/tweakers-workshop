# Guestbook

## Dependencies

[Docker](https://docs.docker.com/install/)

[Mysql](https://dev.mysql.com/downloads/installer/)

## Repository

Clone this repository and go to the directory:

```bash
git clone $REPO
cd guestbook
```

## Workshop 2-2

Create our Dockerfile in the guestbook directory

```bash
cd guestbook
vim Dockerfile
```

### Copy of the final Dockerfile if needed:

https://gist.githubusercontent.com/Seth-Karlo/01a3b35cf7f7a373d0764dbff819735b/raw/346e05797294566922ecfe4b56f8ea74c58c0297/Dockerfile

## Workshop 2-3

### Building our image

```bash
cd guestbook
docker build .
```

### Tagging our image

```bash
docker tag $image_id_from_before sbpdemo/guestbook
```

### Running our image

```bash
docker run -p 80:80 sbpdemo/guestbook
```

### Running as a daemon

```bash
docker run -p 80:80 -d sbpdemo/guestbook
```

## Workshop 2-4

### Adding a volume

```bash
docker run -p 80:80 --mount source=test,target=/usr/src/app/db -d sbpdemo/guestbook
```

### Test restart

```bash
docker kill $your_container_id
docker run -p 80:80 --mount source=test,target=/usr/src/app/db -d sbpdemo/guestbook
```

## Workshop 2-5

### Adding an environment variable

```bash
docker run -p 80:80 --env NAME="$your_name" --mount source=test,target=/usr/src/app/db/ -d sbpdemo/guestbook
```

## Workshop 3-1

### Connect to your cluster using the script

```bash
cd tweakers-workshop
./workshop.sh connect ${your_user_id}

mv ~/.kube/config my_kube_config_backup
mv user22.kubeconfig ~/.kube/config
```

Alternatively, you can add `kubeconfig --kubeconfig ${user_id}.kubeconfig` to all of your commands

## Workshop 3-2

### Tagging our image

```bash
docker tag sbpdemo/guestbook sbpdemo/guestbook:${user_ID}
```

### Log into the sbpdemo docker hub account

```bash
docker login
```

If you are already logged into another account, please log out of it first (or feel free to use your own docker hub account if you prefer)

### Push our image

```bash
docker push sbpdemo/guestbook:${user_ID}
```

## Workshop 3-3

### Creating our deployment

```bash
kubectl run my-guestbook --image sbpdemo/guestbook:${user_id}
```

Check on the pods and get the pod name:

```bash
kubectl get pods
```

And port-forward to it, replacing the pod name with your pod name:

```bash
kubectl port-forward my-guestbook-54cc64dbcf-fwds2 8080:80
```

### Expose your guestbook to the internet

```bash
kubectl expose deployment my-guestbook --type=LoadBalancer --port=80
```

Get the service cname:

```bash
$ kubectl get services
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP                                                              PORT(S)        AGE
kubernetes     ClusterIP      100.64.0.1     <none>                                                                   443/TCP        2d
my-guestbook   LoadBalancer   100.67.30.86   a8ef38fb4cfcb11e89b610afb2428ec8-705870703.eu-west-1.elb.amazonaws.com   80:32567/TCP   39s
```

And you can now open it in your browser

## Workshop 3-4

### Redeploy with an environment variable

```bash
kubectl delete deployment my-guestbook

kubectl run my-guestbook --image sbpdemo/guestbook:user1 --env NAME=${your_name_here}
```

## Workshop 3-5

### Create the database

```bash
kubectl apply -f mariadb/
```

### Option 1: Creating the schema yourself (more advanced)

Get the pod name:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
my-guestbook-5cd7c6b86d-jbq29   1/1     Running   0          2m
mysql-5766c846b5-jx5qf          1/1     Running   0          2m
```

Port-forward:

```bash
$ kubectl port-forward mysql-5766c846b5-jx5qf 3306
Forwarding from 127.0.0.1:3306 -> 3306
Forwarding from [::1]:3306 -> 3306
```

Now open a new shell/powershell window

### Running mysql ourselves to import the schema

Test the connection:

```bash
docker run -it mysql:5.6 mysql -h host.docker.internal -u root -p
```

The password is 'password'

And import the schema:

```bash
$ docker run -i mysql:5.6 mysql -h host.docker.internal -u root -ppassword < guestbook/database.sql
Warning: Using a password on the command line interface can be insecure.
Handling connection for 3306
```

Confirm the table is created:

```bash
docker run -it mysql:5.6 mysql -h host.docker.internal -u root -p messages -e "SHOW TABLES;"
Enter password:
Handling connection for 3306
+--------------------+
| Tables_in_messages |
+--------------------+
| messages           |
+--------------------+
```

### Option 2: use a pre-made image

```bash
kubectl patch deployment mysql -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","image":"sbpdemo/mysql:5.6"}]}}}}'
```

### Configure the guestbook to now use the database

```bash
kubectl delete deployment my-guestbook

kubectl run my-guestbook --image sbpdemo/guestbook:user1 --env NAME=Andy --env DATABASE_TYPE="mysql"
```

## Workshop 4-2

### Create the quota

```bash
kubectl create -f quotas-limits/quota.yml
```

### Scale up the guestbook

```bash
kubectl scale deployment my-guestbook --replicas=10
```

You can see the quota prevented the scale up:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
my-guestbook-7965b5f789-ck9jv   1/1     Running   0          8m
mysql-5d76fb8d49-dxnnb          1/1     Running   0          9m
```

### Debugging what went wrong

```bash
$ kubectl get replicasets
NAME                      DESIRED   CURRENT   READY   AGE
my-guestbook-7965b5f789   10        1         1       22m
mysql-5d76fb8d49          1         1         1       19m

kubectl describe replicaset my-guestbook-7965b5f789
Name:           my-guestbook-7965b5f789
Events:
  Type     Reason            Age                   From                   Message
  ----     ------            ----                  ----                   -------
  Normal   SuccessfulCreate  24m                   replicaset-controller  Created pod: my-guestbook-7965b5f789-dbctw
~~~Truncated~~~
  Warning  FailedCreate      3m23s                 replicaset-controller  Error creating: pods "my-guestbook-7965b5f789-j2wkr" is forbidden: failed quota: k8s-quota: must specify limits.cpu,limits.memory,requests.memory
  Warning  FailedCreate      2m3s (x6 over 3m22s)  replicaset-controller  (combined from similar events): Error creating: pods "my-guestbook-7965b5f789-wdhgm" is forbidden: failed quota: k8s-quota: must specify limits.cpu,limits.memory,requests.memory
```

## Workshop 4-3

### Redeploying with requests and limits set

```bash
kubectl delete deployment my-guestbook
kubectl run my-guestbook --image sbpdemo/guestbook:user1 --env NAME=Andy --env=DATABASE_TYPE=mysql --requests='cpu=100m,memory=256Mi' --limits='cpu=150m,memory=512Mi' --replicas=10
```

The quota prevented more than four pods from starting:

```bash
$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
my-guestbook-97f659799-6jmq9   1/1     Running   0          1m
my-guestbook-97f659799-9c4p6   1/1     Running   0          1m
my-guestbook-97f659799-btxcs   1/1     Running   0          1m
my-guestbook-97f659799-x9w59   1/1     Running   0          1m
mysql-5d76fb8d49-dxnnb         1/1     Running   0          15m
```

Another describe of the replica set shows this:

```bash
$ kubectl describe replicaset my-guestbook-97f659799
  Warning  FailedCreate      3m30s                   replicaset-controller  Error creating: pods "my-guestbook-97f659799-kdm8g" is forbidden: exceeded quota: k8s-quota, requested: limits.memory=512Mi, used: limits.memory=2Gi, limited: limits.memory=2Gi
```


