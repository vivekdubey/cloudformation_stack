# Cloudformation Stack #

It's a rubygem written to create/update cloudformation stack. It creates the stack if not present and updates an existing stack. Basic idea behind this is to mimic AWS console for creating or updating a cloudformation stack.

## Features ##

### Timeout ###
- Setup custom timeout value to override cloudformation's default timeout which is alot.
- It helps in controlled failure of cloudformation deployment where a resource (e.g ECS) never signals it's failure back to CF stack. 
### Handle edge cases of ECS and other similar services ###
- In case ECS fails to place containers it doesn't signal cloudformation within in a specified time.
- Because of that cloudformation stack keeps waiting for ECS to become stable.
- If only ECS is being deployed using cloudformation it's impossible to signal cloudformation stack.
- Setting up custom timeout lets the deployment timeout in a controlled way.
### Various authentication mechanism ###
- Assume IAM Role based authentication.
- AWS profile based authentication.
- Access key based authentication

## Parameters needed to use the gem ##
### Cloudformation template ###
- JSON or YAML format
### Values for Parameters declared in cloudformation template ###
- Snippet from examples in the repository
```
   cf_template_parameters = {
      ImageId: 'ami-abc123d',
      InstanceType: 't2.nano',
      KeyName: 'test-key'
    }
```
### Stack Name ###
- Unique Stack name for the undergoing cloudformation deployment.
### Disable rollback flag ###
- set to `true` if stack should stay if creation failed.
- set to `false` if stack should get deleted if creation failed.
### Timeout ###
- timeout in seconds.
- default value: `600 seconds`.
- If stack creation/updation doesn't fail/complete within specified time, aws-sdk sends failed signal to cloudformation and makes it rollback.
### Credential/Authentication Parameters ###
#### IAM role based authencation ####
- It uses IAM role to authenticate with AWS API.
- It can be invoked from an EC2 instance assigned an IAM role.
- It needs the role to assume in order to create/update cloudformation in the desired account. 
- Credentials params for IAM role based authentication(assumed role) has to be passed as given below:
##### Credential parameter format for IAM based authentication #####
```
credential_params = {
      mode: 'iam_role_arn', # Mandatory parameter.
      iam_role_arn: 'arn:aws:iam::12345678:role/exampleRole' # Mandatory if mode == iam_role_arn
    }
```
#### AWS profile based authentication ####
- It uses aws profile configured for running awscli commands.
- It can be used to authenticate AWS SDK to invoke AWS APIs.
##### Credential parameter format for AWS Profile based authentication #####
```
credential_params = {
      mode: 'aws_profile', # Mandatory parameter.
      profile_name: 'example_aws_profile' # Mandatory if mode == aws_profile
    }
```
#### Access key based authentication ####
- It's the most basic authentication method.
- In order to use this way, either values need to be passed explicitlty or certain environment variables need to be set.
- `access_key_id` isn't needed if `ENV['AWS_ACCESS_KEY_ID']` is set.
- `secret_access_key` isn't needed if `ENV['AWS_SECRET_ACCESS_KEY'],` is set.
- `session_token` isn't needed if `ENV['AWS_SESSION_TOKEN']` is set. 

*Note: `session_token` is needed only when access key is for federate access*
##### Credential parameter format for Access key based authentication #####
```
credential_params = {
      mode: 'aws_access_key', # Mandatory parameter.
      access_key_id: 'SAMPLEACCESSKEYID', # Mandatory if mode == aws_access_key
      secret_access_key: 'SAMPLESECRETACCESSKEY', 
      session_token: 'SAMPLESESSIONTOKEN',  
    }
```
## How to use the gem? ##
```
require 'cloudformation_stack'                                       # Using gem

cf_template_parameters = {                                           # CF template Parameters.
  Param1: 'Param1 Value',
  Param2: 'Param2 Value',
  .
  .
  ParamN: 'ParamN Value'
}
cf_stack_name = <Cloudformation stack name>                          # CF stack name.
cf_template_body = File.read('<Template path>/sample_cf.template') . # Cloudformation template.  
credential_params = {                                                # Credentials parameters as per instructions given above.
  mode: 'aws_profile | iam_role_arn | aws_access_key',
  profile_name: 'profile name',
  iam_role_arn: 'iam_role_arn',
  access_key_id: 'access_key_id | ENV['AWS_ACCESS_KEY_ID']',
  secret_access_key: 'secret_access_key | ENV['AWS_SECRET_ACCESS_KEY']',
  session_token: 'session_token | ENV['AWS_SESSION_TOKEN'] (optional. Needed if profile is federated access)'
}
disable_rollback = <true | false>                                     # True: Don't rollback, False: Rollback
timeout = N <seconds>                                                 # Timeout when creation/updation stops.
region = <AWS region>                                                 # AWS region where stack needs to be.

# Deployment steps. Invoking classes and functions from the gem
cf_stack = CFStackService.new(cf_stack_name, cf_template_body, cf_template_parameters, credential_params, region)
cf_stack.deploy(disable_rollback,timeout)
```
## [Examples](https://github.com/vivekdubey/cloudformation_stack/tree/v4/examples) explained ##
- Examples can be referred to use the gem as per ones comfort.
- Examples in the repository use rake task to invoke.
- Gem can invoked differently as well. 
- Sample cloudformation template can be found inside examples directory with relevant rake tasks.

### Case1 : IAM role based authentication ###
```
# iam_role_arn : Assumed IAM role ARN.
# region : AWS region where cloudformation stack is deployed to.
# keyname, instance_type, image_id :  map to corresponding parameters in cloudformation template.
# timeout : Timeout in seconds, after which cloudformation deployment will rollback.
task :deploy_with_iam_role, [:iam_role_arn, :region, :keyname, :instance_type, :image_id, :timeout] do |t, args|
    cf_template_parameters = {
      ImageId: args[:image_id],                         # ImageId      : Parameter defined in CF template.
      InstanceType: args[:instance_type],               # InstanceType : Parameter defined in CF template.
      KeyName: args[:keyname]                           # KeyName      : Parameter defined in CF template.
    }
    cf_stack_name = "sample-stack"                      # Name of cloudformation stack
    cf_template_body = File.read('sample_cf.template')  # Cloudformation template.
    credential_params = {                               # Credentials parameter defined as per authentication mode.
      mode: 'iam_role_arn',
      iam_role_arn: args[:iam_role_arn]
    }
    disable_rollback = true                             # disable_rollback : true | false (To rollback in case of failure)
    
    # Steps to invoke gem's method to deploy AWS stack
    cf_stack = CFStackService.new(cf_stack_name, cf_template_body, cf_template_parameters, credential_params, args[:region])
    cf_stack.deploy(disable_rollback,args[:timeout])
end
```
### Case2 : AWS profile based authentication ###
```
# aws_profile : AWS profile configured in ~/.aws/credentials .
# region : AWS region where cloudformation stack is deployed to.
# keyname, instance_type, image_id :  map to corresponding parameters in cloudformation template.
# timeout : Timeout in seconds, after which cloudformation deployment will rollback.
task :deploy_with_aws_profile, [:aws_profile, :region, :keyname, :instance_type, :image_id, :timeout] do |t, args|
    cf_template_parameters = {
      ImageId: args[:image_id],                         # ImageId      : Parameter defined in CF template.
      InstanceType: args[:instance_type],               # InstanceType : Parameter defined in CF template.
      KeyName: args[:keyname]                           # KeyName      : Parameter defined in CF template.
    }
    cf_stack_name = "sample-stack"                      # Name of cloudformation stack
    cf_template_body = File.read('sample_cf.template')  # Cloudformation template.
    credential_params = {                               # Credentials parameter defined as per authentication mode.
      mode: 'aws_profile',
      profile_name: args[:aws_profile]
    }
    disable_rollback = true                             # disable_rollback : true | false (To rollback in case of failure)
    
    # Steps to invoke gem's method to deploy AWS stack
    cf_stack = CFStackService.new(cf_stack_name, cf_template_body, cf_template_parameters, credential_params, args[:region])
    cf_stack.deploy(disable_rollback,args[:timeout])
end
```
### Case3 : Access key based authentication ###
```
# access_key_id, secret_access_key, session_token : In case environment variables are not.
# region : AWS region where cloudformation stack is deployed to.
# keyname, instance_type, image_id :  map to corresponding parameters in cloudformation template.
# timeout : Timeout in seconds, after which cloudformation deployment will rollback.
task :deploy_with_access_key, [:region, :keyname, :instance_type, :image_id, :timeout, :access_key_id, :secret_access_key, :session_token] do |t, args|
    cf_template_parameters = {
      ImageId: args[:image_id],                         # ImageId      : Parameter defined in CF template.
      InstanceType: args[:instance_type],               # InstanceType : Parameter defined in CF template.
      KeyName: args[:keyname]                           # KeyName      : Parameter defined in CF template.
    }
    cf_stack_name = "sample-stack"                      # Name of cloudformation stack
    cf_template_body = File.read('sample_cf.template')  # Cloudformation template.
                                   
    credential_params = {                               # Credentials parameter defined as per authentication mode.
      mode: 'aws_access_key',
      access_key_id: args[:access_key_id], # No need to pass it, if ENV['AWS_ACCESS_KEY_ID']
      secret_access_key: args[:secret_access_key], # No need to pass it, if ENV['AWS_SECRET_ACCESS_KEY']
      session_token: args[:session_token] # No need to pass it, if ENV['AWS_SESSION_TOKEN']
    }
    disable_rollback = true                             # disable_rollback : true | false (To rollback in case of failure)
    
    # Steps to invoke gem's method to deploy AWS stack
    cf_stack = CFStackService.new(cf_stack_name, cf_template_body, cf_template_parameters, credential_params, args[:region])
    cf_stack.deploy(disable_rollback,args[:timeout])
end
```
