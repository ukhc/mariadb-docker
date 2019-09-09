# MariaDB for Docker and Kubernetes

## Reference
- https://hub.docker.com/_/mariadb

## Docker deployment to the local workstation

~~~
# start the container
docker run --name mariadb -p 3306:3306 -e MYSQL_ROOT_PASSWORD=admin -d mariadb:10.4.6

# see the status
docker container ls

# destroy the container
docker container stop mariadb
docker container rm mariadb
~~~


## Kubernetes deployment to the local workstation (macOS only)

## Prep your local workstation (macOS only)
1. Clone this repo and work in it's root directory
1. Install Docker Desktop for Mac (https://www.docker.com/products/docker-desktop)
1. In Docker Desktop > Preferences > Kubernetes, check 'Enable Kubernetes'
1. Click on the Docker item in the Menu Bar. Mouse to the 'Kubernetes' menu item and ensure that 'docker-for-desktop' is selected.

### Deploy (run these commands from the root folder of this repo)
~~~
./local-apply.sh
~~~

Note: The default mysql root password is admin

### Delete
~~~
./local-delete.sh
~~~

### Create a backup of the persistent volume
~~~
./local-backup.sh
~~~

### Restore from backup (pass it the backup folder name)
~~~
./local-restore.sh 2019-10-31_20-05-55
~~~

### Restart the deployment
~~~
./local-restart.sh
~~~

### Scale the deployment
~~~
kubectl scale --replicas=4 deployment/mariadb
~~~

## How to override values in the Kubernetes deployment

Use this pattern in a script
~~~
# copy the file to a temp file
cp ./kubernetes/mariadb-single.yaml yaml.tmp

# replace the values with sed in the temp file
sed -i '' 's/storage:.*/storage: default/' yaml.tmp

# deploy from the temp file
kubectl apply yaml.tmp

# delete the temp file
rm -f yaml.tmp
~~~

### Values to override

storage: 5Gi (the size of the persistent volume claim)
~~~
sed -i '' 's/storage:.*/storage: default/' yaml.tmp
~~~

password: YWRtaW4=  (the password for the mysql root account)
~~~
# generate a PASSWORD
openssl rand -base64 15

# base64 encode the password, use the result in the sed
echo -n admin | base64

sed -i '' 's/password:.*/password: Base64EncodedPassword/' yaml.tmp

# don't forget to modify the readiness probe with the new password
sed -i '' 's/-padmin/-pYOURNEWPASSWORD/' yaml.tmp

# base64 decode the password, if you need to see what it is
echo YWRtaW4= | base64 --decode
~~~

storageClassName: mariadb  (if you're deploying to a cloud provider, look at what they offer)
~~~
sed -i '' 's/storageClassName:.*/storageClassName: managed-premium/' yaml.tmp
~~~

## Jenkins for keeping a copy of the Docker Image

Jenkins will ensure the versions of the Docker Hub image exist in our Docker Registry based on the versions listed in the `docker-registry-versions.txt`.


Jenkins uses the Job DSL plugin to create the jobs.  


## Managing the database

### Use a proxy to connect a management tool to your local instance
~~~
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD 3306:3306
~~~

### Use kubectl commands to manage the database

#### Create a database
~~~
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'create database mydatabase'
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'show databases'
~~~

#### Delete a database
~~~
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'drop database mydatabase'
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'show databases'
~~~

#### Export and import a database
~~~
# export
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysqldump -u root -padmin mydatabase > mydatabase-dump.sql

# import
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'create database mydatabase'
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin mydatabase < mydatabase-dump.sql

# validate
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'use mydatabase;show tables;'
~~~
