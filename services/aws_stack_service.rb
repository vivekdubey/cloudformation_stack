require 'json'
require 'cfndsl'

class CFStackService
  attr_reader :stack_name, :template_params, :template_body
  def initialize(stack_name, template_body, template_params, credentials)
    @stack_name = stack_name
    @cf = cf_client(stack_name, template_body, template_params, credentials)
    @template_body = template_body
    @template_params = template_params
  end

  def deploy(disable_rollback=false)
    if exists?
      Log.error "Cloudformation stack can't be deployed\n:Stack Name:  #{stack_name}\n Stack status: #{stack_status}" unless is_valid_status?
      Log.info "Updating cloudformation stack...\n Stack Name: #{stack_name}"
      catch_stack_validation_error { update }
    else
      Log.info "Creating cloudformation stack...\n Stack Name: #{stack_name}"
      catch_stack_validation_error { create disable_rollback }
    end
  end

  def exists?
    @cf.stack_exists?
  end

  def create disable_rollback
    stack = @cf.create_stack disable_rollback
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'CREATE_COMPLETE'
    stack
  end

  def update
    stack = @cf.update_stack
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'UPDATE_COMPLETE'
    stack
  end

  def stack_status
    @cf.stack_status
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
