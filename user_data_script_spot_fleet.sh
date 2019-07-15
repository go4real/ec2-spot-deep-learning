#!/bin/bash
# Get instance ID, Instance AZ, Volume ID and Volume AZ 
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=ap-northeast-2

# Make directories
mkdir /dltraining
chown -R ubuntu: /dltraining/

# Get training code
# git clone https://github.com/go4real/ec2-spot-deep-learning.git
# chown -R ubuntu: ec2-spot-deep-learning
cd /home/ubuntu/ec2-spot-deep-learning

# Initiate training using the tensorflow_36 conda environment
sudo -H -u ubuntu bash -c "source /home/ubuntu/anaconda3/bin/activate tensorflow_p36; python ec2_spot_keras_training.py"

# Store Trained Data to S3


# After training, clean up by cancelling spot requests and terminating itself
# SPOT_FLEET_REQUEST_ID=$(aws ec2 describe-spot-instance-requests --region $AWS_REGION --filter "Name=instance-id,Values='$INSTANCE_ID'" --query "SpotInstanceRequests[].Tags[?Key=='aws:ec2spot:fleet-request-id'].Value[]" --output text)
# aws ec2 cancel-spot-fleet-requests --region $AWS_REGION --spot-fleet-request-ids $SPOT_FLEET_REQUEST_ID --terminate-instances
