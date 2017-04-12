require 'aws-sdk'
require 'pp'
class CloudFormation
  attr_reader :stack_name, :template_body, :template_params
  def initialize(stack_name, template_body, template_params, credentials)
    @stack_name = stack_name
    @template_body = template_body
    @template_params = template_params
    @cf = cf_client(credentials[:aws_profile], credentials[:region])
    @stack = Aws::CloudFormation::Stack.new(stack_name,{client: @cf})
  end

  def stack_status
    response = @cf.describe_stacks({stack_name:stack_name})
    response.stacks[0].stack_status
  end

  def events
    @stack.events.map do |event|
      {
        time: event.timestamp,
        status: event.resource_status,
        type: event.resource_type,
        logical_id: event.logical_resource_id,
        physical_id: event.physical_resource_id,
        reason: event.resource_status_reason
      }
    end
  end

  def create_stack(disable_rollback)
    Log.error "Stack #{stack_name} already exists and cannot be created." if stack_exists?
    Log.info("Creating stack #{stack_name} with parameters:")
    pp template_params
    Dir.mktmpdir do |template_dir|
      @cf.create_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"],
        parameters: template_params.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
        disable_rollback: disable_rollback,
        timeout_in_minutes: 30
      })
      result = catch(:success) do
        waiter(stack_name, Constants::END_STATES, "CREATE")
      end
    end
  end

  def update_stack
    Log.info("Updating stack #{stack_name} with parameters:")
    pp template_params
    Dir.mktmpdir do |template_dir|
      @cf.update_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"],
        parameters: template_params.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
      })
      catch(:success) do
        waiter(stack_name, Constants::END_STATES, "UPDATE")
      end
    end
  end

  def stack_exists?
    Log.info "Checking if stack #{stack_name} exists"
    @stack.exists?
  end

  private

  def cf_client(aws_profile, region)
    credentials = Aws::SharedCredentials.new(profile_name: aws_profile).credentials
    Aws::CloudFormation::Client.new(credentials: credentials, region: region)
  end

  def waiter(stack_name, applicable_end_states, operation)
    waiter_name = :stack_create_complete if operation == "CREATE"
    waiter_name = :stack_update_complete if operation == "UPDATE"
      begin
        @cf.wait_until(waiter_name, stack_name: stack_name) do |w|
          w.interval = 20
          w.max_attempts = 180
          w.before_wait do |n, resp|
            response = @cf.describe_stacks({stack_name:stack_name})
            if response.stacks.empty? || applicable_end_states.include?(response.stacks[0].stack_status)
              throw :success, response.stacks[0].stack_status
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
