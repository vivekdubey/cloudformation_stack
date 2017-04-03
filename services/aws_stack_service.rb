require 'json'
require 'cfndsl'

class AWSStackService
  attr_reader :stack_name, :template_params, :template_body
  def initialize(stack_name, template_body, template_params, credentials)
    @stack_name = stack_name
    @cf_client = cf_client(stack_name, template_body, template_params, credentials)
    @template_body = template_body
    @template_params = template_params
  end

  def deploy
    if exists?
      abort "CFN Stack blocked (status = #{stack_status})" unless is_valid_status?
      Log.info "CFN Stack pre-existing, updating it..."
      catch_stack_validation_error { update }
    else
      Log.info "CFN Stack inexistent, creating it..."
      catch_stack_validation_error { create true }
    end
  end

  def exists?
    @cf_client.stack_exists?(stack_name)
  end

  def create disable_rollback
    stack = @cf_client.create_stack stack_name, template_params, disable_rollback, template_body
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'CREATE_COMPLETE'
    stack
  end

  def update
    stack = @cf_client.update_stack stack_name, template_params, template_body
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'UPDATE_COMPLETE'
    stack
  end

  def delete wait_for_operation_completion
    @cf_client.delete_stack stack_name, wait_for_operation_completion
  end

  def stack_status
    @cf_client.get_stack(stack_name).stack_status
  end

  def is_valid_status?
    ! stack_status.match(/_COMPLETE$/).nil?
  end

  private
  def cf_client(stack_name, template_body, template_params, credentials)
    CloudFormation.new(stack_name, template_body, template_params, credentials)
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

end
