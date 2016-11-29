class CFStack

  def initialize(environment, aws_config, stack)
    @environment = environment
    @aws_config = aws_config
    @stack = stack
  end

  def stack_id
    @stack.stack_id
  end

  def stack_name
    @stack.stack_name
  end

  def stack_status
    @stack.stack_status
  end

  def in_failure_state?
    Constants::FAILURE_END_STATES.include?(@stack.stack_status)
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

end
