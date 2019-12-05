#!/bin/bash

# cleanup environment
DATAHUB_INST=${HOME}/SAPDataHub-2.7.152-Foundation
sdh_worker_role=$(aws iam list-instance-profiles | jq -r '.InstanceProfiles[] |
          select(.InstanceProfileName | test("worker-profile")) | .Roles[] |
          select(.RoleName | test("worker-role")) | "\(.RoleName)"')


## Deinstall SAP DataHub
pushd $DATHUB_INST
./install.sh -p 
popd

## delete ECR policy from worker nodes
aws iam detach-role-policy --role-name ${sdh_worker_role}  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

## destroy OCP Cluster
openshift-install destroy cluster --dir=${HOME}/sdh-${GUID}

## remove ECR registry
ansible-playbook -e repo_state=absent configure-ecr.yml

## delete remaining installer files
rm -rf ${HOME}/.kube
rm -rf ${HOME}/sdh-${GUID}







