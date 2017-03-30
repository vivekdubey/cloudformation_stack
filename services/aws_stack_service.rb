require 'json'
require 'cfndsl'

class AWSStackService
  attr_reader :stack_name, :template_params, :template_body
  def initialize(stack_name, template_body, template_params, cf_client)
    @stack_name = stack_name
    @cf_client = cf_client
    @template_body = template_body
    @template_params = template_params
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

end
