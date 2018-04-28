#Execute chmod 755 create-env.sh
#Run the script by typing sh create-env.sh
# Author: Mohnish Anand

#!/bin/bash
#Stop executing if error occurs
set -e
#Verbose output
#set -v

#echo "Enter AMI ID : "
#read ami_id
#echo "Enter Number of instances you want to create (count) : "
#read count
#Uncommnet below after final test run
echo "Enter the name of keypair you want to associate with EC2 Instances : "
read key_pair
echo "Enter the name of security group you want to associate with ASG EC2 and Redis instance : "
read sg
echo "Enter IAM Role name to be associated with Auto Scaling Group : "
read iamrole
echo "Enter Minimum Instance Required for Scaling Group - Desired Value is 1"
read min_instances
echo "Enter Maximum Instances Required for Scaling Group - Desired Value is 3 or 5"
read max_instances
echo "Enter VPC ID you want to associate with Loab Balancer :"
read vpcid

ami_id=ami-43a15f3e
#Commnet below after final test run
#key_pair=itmo-544-key
#sg=sg-036c9a70
#min_instances=1
#max_instances=3
#vpcid=vpc-8cb737f5
#iamrole=test-ec2

echo $ami_id
echo $count
echo $key_pair
echo $sg
echo $min_instances
echo $max_instances

#open database port in security group

#Create IAM Roles and assign Policies to it
#aws iam create-role --role-name auto-scaling-role --assume-role-policy-document file://./iam-policies/auto-scaling-role.json
#aws iam put-role-policy --role-name auto-scaling-role --policy-name S3-Rds-Ec2-Full --policy-document file://./iam-policies/s3-rds-ec2-policy.json

#Create Redis Multi AZ Cluster Disabled Instance
aws elasticache create-replication-group \
--replication-group-id redis-group \
--replication-group-description "My Redis Description" \
--automatic-failover-enabled \
--num-cache-clusters 2 \
--cache-node-type cache.m3.medium  \
--engine redis \
--engine-version 3.2.10 \
--cache-subnet-group-name default \
--security-group-ids $sg

#aws rds wait db-instance-available --db-instance-identifier mydbinstance

#Get the list of subnets from the VPC
#subnets=$(aws ec2 describe-subnets --filters "Name =vpc-id,Values=$vpcid" --query 'Subnets[*].[SubnetId]')
subnets=`aws ec2 describe-subnets --filters  --query 'Subnets[*].SubnetId' --output text | grep "subnet-"`
echo $subnets

#Creating Launch Config
aws autoscaling create-launch-configuration --key-name $key_pair --launch-configuration-name redis-lc \
--image-id $ami_id --instance-type t2.micro --security-groups $sg --instance-monitoring Enabled=true --user-data file://enable-redis-access.sh
#--no-associate-public-ip-address

#Creating Load Balancer and Target Group
LB_ARN=$(aws elbv2 create-load-balancer --name redis-lb \
--subnets $subnets \
--security-groups $sg | grep LoadBalancerArn | grep -o -P '(?<="LoadBalancerArn": ").*(?=")')
echo $LB_ARN

#Creating Load Balancer
TARGET_ARN=$(aws elbv2 create-target-group --name redis-targets \
--protocol HTTP --port 80 --vpc-id $vpcid | grep TargetGroupArn | grep -o -P '(?<="TargetGroupArn": ").*(?=")')
echo $TARGET_ARN

#Create Load Balancer Listener
aws elbv2 create-listener --load-balancer-arn $LB_ARN \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=$TARGET_ARN


#Create Auto Scaling Group with target-group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name redis-asg \
--launch-configuration-name redis-lc \
--availability-zones us-east-1c \
--target-group-arns $TARGET_ARN \
--min-size $min_instances --max-size $max_instances --desired-capacity 2

#Create Scale Out Policy
SOUT_ARN=$(aws autoscaling put-scaling-policy \
--policy-name my-scaleout-policy \
--auto-scaling-group-name redis-asg \
--scaling-adjustment 2 \
--adjustment-type ChangeInCapacity | grep PolicyARN | grep -o -P '(?<="PolicyARN": ").*(?=")')

#Create Scale In Policy
SIN_ARN=$(aws autoscaling put-scaling-policy \
--policy-name my-scalein-policy \
--auto-scaling-group-name redis-asg \
--scaling-adjustment -2 \
--adjustment-type ChangeInCapacity | grep PolicyARN | grep -o -P '(?<="PolicyARN": ").*(?=")')

#Create Alarms Add Capacity
aws cloudwatch put-metric-alarm \
--alarm-name AddCapacity --metric-name \
CPUUtilization --namespace AWS/EC2 \
--statistic Average --period 120 \
--threshold 80 \
--comparison-operator GreaterThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=redis-asg" \
--evaluation-periods 2 --alarm-actions $SOUT_ARN

#Create Alarm Remove Capacity
aws cloudwatch put-metric-alarm \
--alarm-name RemoveCapacity \
--metric-name CPUUtilization \
--namespace AWS/EC2 \
--statistic Average \
--period 120 \
--threshold 40 \
--comparison-operator LessThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=redis-asg" \
--evaluation-periods 2 \
--alarm-actions $SIN_ARN
