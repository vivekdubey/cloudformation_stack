def exit_on_mandatory_rake_arguments args, *arguments
  error_messages = arguments.inject([]) do |messages, argument|
    if args[argument].nil?
      messages.push "Mandatory rake argument: #{argument.to_s}"
    end
    messages
  end

  if error_messages.size > 0
    Log.error 'Exiting on error. Missing mandatory rake arguments.' + "\n " + error_messages.join('\n')
  end
end

def deploy_variables
  abort "Error! variables.json file missing" if not File.exists?("variables.json")
  @deploy_variables ||=JSON.load(File.read("variables.json"))
end
