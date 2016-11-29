def create_aws_stack_service(stack_creation_params)
  aws_config = AWSConfig.new(stack_creation_params[:aws_profile], stack_creation_params[:region])
  cloudformation = CloudFormation.new stack_creation_params[:environment], aws_config
  AWSStackService.new(stack_creation_params.merge({cloudformation: cloudformation}))
end

def check_stack_or_abort! aws_stack_service
  if aws_stack_service.exists?
    abort "CFN Stack blocked (status = #{aws_stack_service.stack_status})" unless aws_stack_service.is_valid_status?
  end
end

def catch_stack_validation_error
  begin
    stack = yield
    write_log stack.events
  rescue Aws::CloudFormation::Errors::ValidationError, Aws::Waiters::Errors::FailureStateError, Aws::CloudFormation::Errors::InvalidStatus => e
    if e.instance_of? Aws::Waiters::Errors::FailureStateError
      Log.error_and_continue "#{e.response}"
      exit 1
    elsif e.class.name ==  'Aws::CloudFormation::Errors::ValidationError' && e.message == "No updates are to be performed."
      Log.warn "#{e.message}"
    else
      Log.error_and_continue "#{e}"
      exit 1
    end
    exit 1 unless e.class.name ==  'Aws::CloudFormation::Errors::ValidationError' && e.message == "No updates are to be performed."
  end
end

def write_log events
  build_log_folder = 'cloud_formation_logs'
  FileUtils.rm_rf build_log_folder
  Dir.mkdir build_log_folder
  File.write File.join(build_log_folder,"events.log"), events.to_json
end
