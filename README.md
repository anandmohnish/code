# Deploying Auto Scaling Group with Redis Group

#### ** From the development box  i.e. from where create-env.sh is executed, execute aws configure and set default output mode to json. If output mode is not set to json the scripts will fail and incomplete infrastructure will be created. It is also assumed that AWS Secret ID and Key are also configured.

### Before Running the code, do this -
 1. Run aws configure , on the machine you will run the code from. Set Default region and Default output to us-east-1 and json.
 ![Install-Plugins](images/Capture-aws-configure.JPG)

### How to run the code ?
 1. Download the git repo to a location.
 2. From the location cd test
 3. Type sh create-env.sh
 4. It will ask for various inputs and then create the infrastructure on AWS.

 ### Destroy the App ?
 1. cd test on the location where the git repo was downloaded.
 2. Type - sh destroy-env.sh


 #### ** Script asks for various inputs, such as :
 1. Key Pair Name
 2. Security Group
 3. Minimum Instance Required for Scaling Group
 4. Maximum Instance Required for Scaling Group
 5. VPCID

#### ** Redis instance can be scaled using the below command when required (it will scale UP to R4 instance type) :
  1. aws elasticache modify-replication-group \
	    --replication-group-id redis-group \
	    --cache-node-type cache.r4.large \
	    --apply-immediately
#### ** The code launches all instances in us-east-1 region
#### ** The code assumes that for the security group being entered has the below ports open in the security group
  1. 22
  2. 80 (not required at moment for the requirements given by you)
  3. 6379  
