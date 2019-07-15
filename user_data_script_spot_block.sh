#!/bin/bash
# Get instance ID, Instance AZ, Volume ID and Volume AZ 
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=ap-northeast-2

VOLUME_ID=$(aws ec2 describe-volumes --region $AWS_REGION --filter "Name=tag:Name,Values=DL-datasets-checkpoints" --query "Volumes[].VolumeId" --output text)
VOLUME_AZ=$(aws ec2 describe-volumes --region $AWS_REGION --filter "Name=tag:Name,Values=DL-datasets-checkpoints" --query "Volumes[].AvailabilityZone" --output text)

echo "Volume handling ====="
# Proceed if Volume Id is not null or unset
if [ $VOLUME_ID ]; then
		# Check if the Volume AZ and the instance AZ are same or different.
		# If they are different, create a snapshot and then create a new volume in the instance's AZ.
		if [ $VOLUME_AZ != $INSTANCE_AZ ]; then
				SNAPSHOT_ID=$(aws ec2 create-snapshot \
						--region $AWS_REGION \
						--volume-id $VOLUME_ID \
						--description "`date +"%D %T"`" \
						--tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=DL-datasets-checkpoints-snapshot}]' \
						--query SnapshotId --output text)

				aws ec2 wait --region $AWS_REGION snapshot-completed --snapshot-ids $SNAPSHOT_ID
				aws ec2 --region $AWS_REGION  delete-volume --volume-id $VOLUME_ID

				VOLUME_ID=$(aws ec2 create-volume \
						--region $AWS_REGION \
								--availability-zone $INSTANCE_AZ \
								--snapshot-id $SNAPSHOT_ID \
						--volume-type gp2 \
						--tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=DL-datasets-checkpoints}]' \
						--query VolumeId --output text)
				aws ec2 wait volume-available --region $AWS_REGION --volume-id $VOLUME_ID
		fi
		# Attach volume to instance
		aws ec2 attach-volume \
			--region $AWS_REGION --volume-id $VOLUME_ID \
			--instance-id $INSTANCE_ID --device /dev/sdf
		sleep 10

		# Mount volume and change ownership, since this script is run as root
		mkdir /dltraining
		mount /dev/xvdf /dltraining
		chown -R ubuntu: /dltraining/
		cd /home/ubuntu/

		# Get training code
		git clone https://github.com/awslabs/ec2-spot-labs.git
		chown -R ubuntu: ec2-spot-labs
		cd ec2-spot-labs/ec2-spot-deep-learning-training/

		echo "START training ====="
		# Initiate training using the tensorflow_36 conda environment
		sudo -H -u ubuntu bash -c "source /home/ubuntu/anaconda3/bin/activate tensorflow_p36; python ec2_spot_keras_training.py"
		echo "END training ====="
fi

echo "Start to Terminate ====="
# After training, clean up by cancelling spot requests and terminating itself
SPOT_INSTANCE_REQUEST_ID=$(aws ec2 describe-spot-instance-requests --region $AWS_REGION --filter "Name=instance-id,Values='$INSTANCE_ID'" --query "SpotInstanceRequests[0].SpotInstanceRequestId" --output text)
aws ec2 cancel-spot-instance-requests --region $AWS_REGION --spot-instance-request-ids $SPOT_INSTANCE_REQUEST_ID
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
