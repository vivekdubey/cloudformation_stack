require 'aws-sdk'
require 'pp'

class CloudFormation

  def initialize(environment, aws_config)
    @aws_config = aws_config
    @environment = environment
    @cloud_formation_client = Aws::CloudFormation::Client.new(aws_config.get)
  end

  def create_stack(stack_name, stack_paramters, disable_rollback, template_body)
    Log.error "Stack #{stack_name} already exists and cannot be created." if stack_exists?(stack_name)
    Log.info("Creating stack #{stack_name} with parameters:")
    pp stack_paramters
    Dir.mktmpdir do |template_dir|
      @cloud_formation_client.create_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"],
        parameters: stack_paramters.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
        disable_rollback: disable_rollback,
        timeout_in_minutes: 30
      })
      result = catch(:success) do
        waiter(stack_name, Constants::END_STATES, "CREATE")
      end
      Log.info result unless result.nil?
      return get_stack(stack_name)
    end
  end

  def update_stack(stack_name, stack_paramters, template_body)
    Log.info("Updating stack #{stack_name} with parameters:")
    pp stack_paramters
    Dir.mktmpdir do |template_dir|
      @cloud_formation_client.update_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"],
        parameters: stack_paramters.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
      })
      result = catch(:success) do
        waiter(stack_name, Constants::END_STATES, "UPDATE")
      end
      Log.info result unless result.nil?
      return get_stack(stack_name)
    end
  end

  def stack_exists?(stack_name)
    Log.info "Checking if stack #{stack_name} exists"
    response = @cloud_formation_client.list_stacks({stack_status_filter: Constants::ALL_STATES})
    response.stack_summaries.any?{|stack| stack.stack_name == stack_name}
  end

  def get_all_stack_names
    response = @cloud_formation_client.list_stacks({stack_status_filter: Constants::ALL_STATES})
    response.stack_summaries.map(&:stack_name)
  end

  def get_stack(stack_name)
    Log.error "The stack #{stack_name} does not exist" if !stack_exists?(stack_name)
    CFStack.new(@environment, @aws_config,Aws::CloudFormation::Stack.new(stack_name,{client: @cloud_formation_client}))
  end

  def validate_template template_body, extras={}
    options = {
      :template_body => template_body
    }
    begin
      @cloud_formation_client.validate_template options
      return { error: nil, valid: true }
    rescue Exception => e
      return { error: e, valid: false }
    end
  end

  private

  def stack_exists_and_not_in_end_state(stack_name)
    stack_summaries = @cloud_formation_client.list_stacks({stack_status_filter: Constants::ALL_STATES}).stack_summaries
    return false if stack_summaries.any?{|stack| stack.stack_name == stack_name && Constants::END_STATES.include?(stack.stack_status)}
    stack_summaries.any?{|stack| stack.stack_name == stack_name}
  end

  def waiter(stack_name, applicable_end_states, operation)
    waiter_name = :stack_create_complete if operation == "CREATE"
    waiter_name = :stack_update_complete if operation == "UPDATE"
      begin
        @cloud_formation_client.wait_until(waiter_name, stack_name: stack_name) do |w|
          w.interval = 20
          w.max_attempts = 180
          w.before_wait do |n, resp|
            response = @cloud_formation_client.describe_stacks({stack_name:stack_name})
            if response.stacks.empty? || applicable_end_states.include?(response.stacks[0].stack_status)
              throw :success, "#{operation} operation on stack #{stack_name} completed with #{response.stacks[0].stack_status}."
            end
            Log.info " #{operation} operation on stack #{stack_name} current status : #{response.stacks[0].stack_status}."
          end
        end
      rescue Exception => e
        Log.error_and_continue "Waiter stopped to get status for operation #{operation}"
        Log.error_and_continue "Waiter Exception : #{e.message}"
      end
  end
end
