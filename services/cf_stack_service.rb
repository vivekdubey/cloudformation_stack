require 'json'

class CFStackService
  attr_reader :stack_name, :template_params, :template_body
  def initialize(stack_name, template_body, template_params, credentials, region)
    @stack_name = stack_name
    @cf_client = cf_client(stack_name, template_body, template_params, credentials, region)
    @template_body = template_body
    @template_params = template_params
  end

  def deploy(disable_rollback=false,timeout=3600)
    if exists?
      Log.error "Cloudformation stack can't be deployed\n:Stack Name:  #{stack_name}\n Stack status: #{stack_status}" unless is_valid_status?
      Log.info "Updating cloudformation stack...\nStack Name: #{stack_name}"
      exception_handler { update(timeout.to_i) }
    else
      Log.info "Creating cloudformation stack...\nStack Name: #{stack_name}"
      exception_handler { create(disable_rollback,timeout.to_i) }
    end
  end

  def exists?
    @cf_client.stack_exists?
  end

  def create(disable_rollback,timeout)
    output = @cf_client.create_stack(disable_rollback,timeout)
    if stack_status == 'CREATE_COMPLETE'
      Log.success "******* #{stack_name} created successfully. *******"
    else
      @cf_client.delete_stack unless disable_rollback
      raise Aws::Waiters::Errors::FailureStateError, stack_status
    end
    return output
  end

  def update(timeout)
    output = @cf_client.update_stack(timeout)
    if stack_status == 'UPDATE_COMPLETE'
      Log.success "******* #{stack_name} updated successfully. *******"
    else
      @cf_client.cancel_update_stack
      raise Aws::Waiters::Errors::FailureStateError, stack_status
    end
    return output
  end

  def stack_status
    @cf_client.stack_status
  end

  def is_valid_status?
    ! stack_status.match(/_COMPLETE$/).nil?
  end

  private
  def cf_client(stack_name, template_body, template_params, credentials, region)
    CloudFormation.new(stack_name, template_body, template_params, Credentials.get(credentials, region), region)
  end
  def exception_handler
    begin
      yield
    rescue Aws::CloudFormation::Errors::ValidationError, Aws::Waiters::Errors::FailureStateError, Aws::CloudFormation::Errors::InvalidStatus => e
      if e.instance_of? Aws::Waiters::Errors::FailureStateError
        Log.error_and_continue "******* #{stack_name} update/create failed. *******"
        Log.error e.response
      elsif e.class.name ==  'Aws::CloudFormation::Errors::ValidationError' && e.message == "No updates are to be performed."
        Log.warn e.message
      else
        Log.error_and_continue "******* #{stack_name} update/create failed. *******"
        Log.error e.message
      end
      exit 1 unless e.class.name ==  'Aws::CloudFormation::Errors::ValidationError' && e.message == "No updates are to be performed."
    end
  end
end
