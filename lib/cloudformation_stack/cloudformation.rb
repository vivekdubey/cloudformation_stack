require 'aws-sdk'
require 'pp'
class CloudFormation
  attr_reader :stack_name, :template_body, :template_params
  def initialize(stack_name, template_body, template_params, credentials, region)
    @stack_name = stack_name
    @template_body = template_body
    @template_params = template_params
    @cf = Aws::CloudFormation::Client.new(credentials: credentials, region: region)
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

  def cancel_update_stack
    @cf.cancel_update_stack({stack_name: stack_name})
  end

  def delete_stack
    @cf.delete_stack({stack_name: stack_name})
  end

  def create_stack(disable_rollback,timeout,tags)
    Log.error "Stack #{stack_name} already exists and cannot be created." if stack_exists?
    Log.info("Creating stack #{stack_name} with parameters:")
    pp template_params
    Dir.mktmpdir do |template_dir|
      @cf.create_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: [ "CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND" ],
        parameters: template_params.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
        disable_rollback: disable_rollback,
        timeout_in_minutes: 30,
        tags: [
          { key: "StackName", value: stack_name},
        ].concat(tags)
      })
      result = catch(:success) do
        waiter(stack_name, Constants::END_STATES, "CREATE", timeout)
      end
    end
  end

  def update_stack(timeout,tags)
    Log.info("Updating stack #{stack_name} with parameters:")
    pp template_params
    Dir.mktmpdir do |template_dir|
      @cf.update_stack({
        stack_name: stack_name,
        template_body: template_body,
        capabilities: [ "CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND" ],
        parameters: template_params.map{|key, value| {parameter_key: key.to_s, parameter_value: value.to_s, use_previous_value: false}},
        tags: [
          { key: "StackName", value: stack_name},
        ].concat(tags)
      })
      catch(:success) do
        waiter(stack_name, Constants::END_STATES, "UPDATE", timeout)
      end
    end
  end

  def stack_exists?
    Log.info "Checking if stack #{stack_name} exists"
    @stack.exists?
  end

  private

  def waiter(stack_name, applicable_end_states, operation, timeout)
    waiter_name = :stack_create_complete if operation == "CREATE"
    waiter_name = :stack_update_complete if operation == "UPDATE"
      begin
        @cf.wait_until(waiter_name, stack_name: stack_name) do |w|
          w.interval = Constants::WAITER_INTERVAL.to_i
          w.max_attempts = (timeout / w.interval).to_i
          w.before_wait do |n, resp|
            response = @cf.describe_stacks({stack_name:stack_name})
            if response.stacks.empty? || applicable_end_states.include?(response.stacks[0].stack_status)
              throw :success, response.stacks[0].stack_status
            end
            Log.info "Attempt: #{n} #{operation} operation on stack #{stack_name} current status : #{response.stacks[0].stack_status}."
          end
        end
      rescue Exception => e
        Log.error_and_continue "Waiter stopped to get status for operation #{operation}"
        Log.error_and_continue "Waiter Exception : #{e.message}"
      end
  end
end
