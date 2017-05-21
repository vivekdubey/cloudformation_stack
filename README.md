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

## Examples ##
Examples demonstrating usage of different authentication 

