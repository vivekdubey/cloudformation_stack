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
#### AWS profile based authentication ####
#### Access key based authentication ####
## Examples ##
Examples demonstrating usage of different authentication 

