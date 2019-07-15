#!/bin/bash
# Get instance ID, Instance AZ, Volume ID and Volume AZ 
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=ap-northeast-2

# Make directories
if [ ! -d "/dltraining" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  mkdir /dltraining
  cd /dltraining
  mkdir datasets
  mkdir checkpoints
  chown -R ubuntu: /dltraining/
fi

# Get training code
# git clone https://github.com/go4real/ec2-spot-deep-learning.git
# chown -R ubuntu: ec2-spot-deep-learning
cd /home/ubuntu/ec2-spot-deep-learning

# Initiate training using the tensorflow_36 conda environment
sudo -H -u ubuntu bash -c "source /home/ubuntu/anaconda3/bin/activate tensorflow_p36; python ec2_spot_keras_training.py"

# Store Trained Data to S3


# After training, clean up by cancelling spot requests and terminating itself
# SPOT_INSTANCE_REQUEST_ID=$(aws ec2 describe-spot-instance-requests --region $AWS_REGION --filter "Name=instance-id,Values='$INSTANCE_ID'" --query "SpotInstanceRequests[0].SpotInstanceRequestId" --output text)
# aws ec2 cancel-spot-instance-requests --region $AWS_REGION --spot-instance-request-ids $SPOT_INSTANCE_REQUEST_ID
# aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
