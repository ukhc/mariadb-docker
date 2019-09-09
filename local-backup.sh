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

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

echo "create timestamp folder..."
BACKUP_FOLDER=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p ./backup/$BACKUP_FOLDER
echo "$BACKUP_FOLDER"

POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")

echo "backup /var/lib/mysql folder..."
mkdir -p ./backup/$BACKUP_FOLDER/html
kubectl cp $POD:/var/lib/mysql ./backup/$BACKUP_FOLDER

echo "...done"