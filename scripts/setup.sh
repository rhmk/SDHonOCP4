#!/bin/bash

#------------------------------------------
# Simple Script to setup SDH environemnt
#------------------------------------------

# Check User, script need to be run as user root
# TODO

# Make sure system is updated and software is installed
echo "Updating system"
sudo yum -y update
sudo yum -y install python2-boto python2-boto3 jq docker

# Read environment and store it
if [ -z "$AWS_ACCESS_KEY" ]; then
   echo -n "Enter AWS ACCESS KEY"
   read AWS_ACCESS_KEY
   export AWS_ACCESS_KEY
else
   echo "AWS_ACCES_KEY is set"
fi

if [ -z "$AWS_SECRET_KEY" ]; then
  echo -n "Enter AWS Secret Key"
  read AWS_SECRET_KEY
  export AWS_SECRET_KEY
else
   echo "AWS_SECRET_KEY is set"
fi

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document/ | jq '.region')
echo -n "Enter Region [${REGION}]"
read r
[ -n "$r" ] && REGION=$r
export REGION

### Create AWS access file and make Environment variables static
cat > ${HOME}/credentials << EOT
export AWS_ACCESS_KEY="$AWS_ACCESS_KEY"
export AWS_SECRET_KEY="$AWS_SECRET_KEY"
export REGION="$REGION"
EOT

mkdir $HOME/.aws
cat << EOF >>  $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
region = $REGION
EOF

if aws sts get-caller-identity; then
  echo "credentials are ok"
else
  rm ${HOME}/credentials
  rm $HOME/.aws/credentials
  echo "ERROR: Credentials are incorrect"
  exit 1
fi


# Create Filename completion
oc completion bash | sudo tee /etc/bash_completion.d/openshift > /dev/null


#sdh_worker_profile=$(aws ec2 describe-instances --filters=Name=instance-state-name,Values=running | jq  -r '.Reservations[].Instances[].IamInstanceProfile.Arn ' | awk -F/ '/worker-profile/ {print $2}' | uniq)

sdh_worker_role=$(aws iam list-instance-profiles | jq -r '.InstanceProfiles[] |
          select(.InstanceProfileName | test("worker-profile")) | .Roles[] |
          select(.RoleName | test("worker-role")) | "\(.RoleName)"')



