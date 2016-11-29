require 'json'
require 'aws-sdk'

class AWSConfig

  def initialize(aws_profile, region)
    @aws_profile = aws_profile
    @region = region
  end

  def get
    credentials = get_credentials_for(@aws_profile).credentials
    {
      access_key_id: credentials.access_key_id,
      secret_access_key: credentials.secret_access_key,
      region: @region
    }
  end

  private

  def get_credentials_for(aws_profile)
    Aws::SharedCredentials.new(profile_name: aws_profile)
  end

end
