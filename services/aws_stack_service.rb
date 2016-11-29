require 'json'
require 'cfndsl'

class AWSStackService
  def initialize service_params
    @environment = service_params[:environment]
    @cloudformation = service_params[:cloudformation]
    @deploy_variables = service_params[:deploy_variables]
    @template_filepath = service_params[:template_filepath]
    @extra_parameters = service_params[:extra_parameters]
  end

  def cloudformation_variables
    @deploy_variables['cloudFormation']['variables'][@environment]
  end

  def stack_name
    @stack_name ||= begin
      name = "#{@environment}-#{@deploy_variables['app']}"
      @deploy_variables['stackNamePrefix'] ? name = "#{@deploy_variables['stackNamePrefix']}-" + name : name
    end
  end

  def add_extra_parameters params
    @extra_parameters.merge! params
  end

  def exists?
    @cloudformation.stack_exists?(stack_name)
  end

  def create disable_rollback
    stack = @cloudformation.create_stack stack_name, parameters, disable_rollback, template_body
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'CREATE_COMPLETE'
    stack
  end

  def update
    stack = @cloudformation.update_stack stack_name, parameters, template_body
    raise Aws::Waiters::Errors::FailureStateError, stack.stack_status unless stack.stack_status == 'UPDATE_COMPLETE'
    # raise Aws::CloudFormation::Errors::InvalidStatus, stack.stack_status unless stack.stack_status == 'UPDATE_COMPLETE'
    stack
  end

  def delete wait_for_operation_completion
    @cloudformation.delete_stack stack_name, wait_for_operation_completion
  end

  def stack_status
    @cloudformation.get_stack(stack_name).stack_status
  end

  def is_valid_status?
    ! stack_status.match(/_COMPLETE$/).nil?
  end

  def template_body
    extras ={}
    extras[:environment] = @environment
    extras[:mappings] = @deploy_variables["cloudFormation"]["mappings"] if @deploy_variables["cloudFormation"]["mappings"]
    @template_body ||= CfnDsl.eval_file_with_extras(@template_filepath, extras).to_json
  end

  private
  def parameters
    variables = {}
    if @deploy_variables['cloudFormation']['variables'][@environment]
      variables.merge! @deploy_variables['cloudFormation']['variables'][@environment]
    else
      raise "Error: Environment cloudFormation/variables/#{@environment} params missing in variables.json"
    end

    variables
      .merge({ 'Environment' => @environment })
      .merge(@extra_parameters)
  end
end
