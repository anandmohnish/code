

#Delete Redis


#Delete AutoScaling Group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name redis-asg --force-delete

#Delete Autoscaling Configuration
aws autoscaling delete-launch-configuration --launch-configuration-name redis-lc

#Delete Scaling Policies
aws autoscaling delete-policy --auto-scaling-group-name redis-asg --policy-name my-scaleout-policy
aws autoscaling delete-policy --auto-scaling-group-name redis-asg --policy-name my-scalein-policy

#Delete Alarm
aws cloudwatch delete-alarms --alarm-names AddCapacity
aws cloudwatch delete-alarms --alarm-names RemoveCapacity

#Delete Load Balancer
lb_arn=$(aws elbv2 describe-load-balancers --names redis-lb | grep LoadBalancerArn | grep -o -P '(?<="LoadBalancerArn": ").*(?=")')
lis_arn=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn |grep ListenerArn | grep -o -P '(?<="ListenerArn": ").*(?=")')
aws elbv2 delete-listener --listener-arn $lis_arn
aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn

#Delete LB Target Group
tg_arn=$(aws elbv2 describe-target-groups --names redis-targets | grep TargetGroupArn | grep -o -P '(?<="TargetGroupArn": ").*(?=")')
#Deregister from target group
aws ec2 describe-instances --query 'Reservations[*] .Instances[*].[InstanceId]' --filters Name=instance-state-name,Values=running --output text >ec2
iid1=$(head -n 1 ec2 | tail -1)
iid2=$(head -n 2 ec2 | tail -1)
iid3=$(head -n 3 ec2 | tail -1)
iid4=$(head -n 4 ec2 | tail -1)
aws elbv2 deregister-targets --target-group-arn $tg_arn --targets Id=$iid1 Id=$iid2
aws elbv2 delete-target-group --target-group-arn $tg_arn
aws ec2 terminate-instances --instance-ids $iid1
aws ec2 terminate-instances --instance-ids $iid2
aws ec2 terminate-instances --instance-ids $iid3
aws ec2 terminate-instances --instance-ids $iid4
