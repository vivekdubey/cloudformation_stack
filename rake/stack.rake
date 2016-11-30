namespace :aws_stack do
  desc 'Deploy application using cloudformation'
  task :vpc_create, [:environment, :aws_profile, :region] do |t, args|
    exit_on_mandatory_rake_arguments args, :environment, :aws_profile, :region
    template_file_path = "cloudformation.rb"
    abort "Error! CloudFormation template missing" if not File.exists?(template_file_path)
    extra_parameters = {}
    stack_creation_params = {
      environment: args[:environment],
      aws_profile: args[:aws_profile],
      region: args[:region],
      template_filepath: template_file_path,
      extra_parameters: extra_parameters,
      deploy_variables: deploy_variables
    }
    aws_stack_service = create_aws_stack_service(stack_creation_params)
    puts aws_stack_service.stack_name
    check_stack_or_abort! aws_stack_service
    unless aws_stack_service.exists?
      Log.info "CFN Stack inexistent, creating it..."
      catch_stack_validation_error { aws_stack_service.create true }
    else
      Log.info "CFN Stack pre-existing, updating it..."
      catch_stack_validation_error { aws_stack_service.update }
    end
  end
end
