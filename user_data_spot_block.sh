#!/bin/bash
cd /home/ubuntu/
git clone https://github.com/go4real/ec2-spot-deep-learning.git
chown -R ubuntu: ec2-spot-deep-learning

cp /home/ubuntu/ec2-spot-deep-learning/spot-block.service /etc/systemd/system/

chmod 664 /etc/systemd/system/spot-block.service
systemctl daemon-reload
systemctl enable spot-block.service
systemctl start spot-block.service
