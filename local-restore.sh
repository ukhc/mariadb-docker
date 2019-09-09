# Copyright (c) 2019, UK HealthCare (https://ukhealthcare.uky.edu) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################
# validate positional parameters

if [ "$1" == "" ]
then
	echo "USEAGE: ./local-restore.sh [BACKUP_FOLDER_NAME]"
	echo "e.g. ./local-restore.sh local_2019-10-31_20-05-55"
	exit 1
fi

BACKUP_FOLDER="$1"
if [ -d "./backup/$BACKUP_FOLDER" ] 
then
    # ./backup/$BACKUP_FOLDER exists
    echo "Restoring from $BACKUP_FOLDER..."
else
    echo "ERROR: Directory ./backup/$BACKUP_FOLDER does not exist"
	exit 1
fi

##########################

echo
echo "*** WARNING: This script will restore the the data in the persistent volumes ***"
echo "*** WARNING: You will lose any changes you have made in the current deployment ***"
echo
read -n 1 -s -r -p "Press any key to continue or CTRL-C to exit..."

echo

##########################

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")

echo "restore html..."
kubectl exec $POD -- bash -c "rm -rf /var/lib/mysql/*"
kubectl cp ./backup/$BACKUP_FOLDER $POD:/var/lib/mysql

##########################

echo "stop the mariadb deployment..."
kubectl scale --replicas=0 deployment mariadb

echo "wait a moment..."
sleep 5

##########################

echo "start the mariadb deployment..."
kubectl scale --replicas=1 deployment mariadb

echo "wait for mariadb..."
sleep 2
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for mariadb pod. Exit script!"
			exit 1
		else
			echo "waiting...mariadb pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################

echo
echo "...done"