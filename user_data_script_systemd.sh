#!/bin/bash
git clone https://github.com/go4real/ec2-spot-deep-learning.git
chown -R ubuntu: ec2-spot-deep-learning

cp /home/ubuntu/ec2-spot-deep-learning/spot-fleet.service /etc/systemd/system/

chmod 664 /etc/systemd/system/spot-fleet.service
systemctl daemon-reload
systemctl enable spot-fleet.service
systemctl start spot-fleet.service
