# Cloudformation Stack #

It's a library written to create/update cloudformation stack. It creates the stack if not present and updates it in subsequent releases to the stack.  

## Quick summary ##
* It's a wrapper written on [aws-sdk(ruby)](http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation.html).
* It's uses all native conventions of [AWS cloudformation service](https://aws.amazon.com/cloudformation/)
* It has some rake tasks for different operations on a stack.
* It takes cloudformation template in [cfndsl](https://github.com/stevenjack/cfndsl) format with some default parameters, defined beforehand and some runtime parameters.
