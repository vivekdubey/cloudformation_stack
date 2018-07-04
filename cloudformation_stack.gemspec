Gem::Specification.new do |s|
  s.name        = 'cloudformation_stack'
  s.version     = '1.0.0'
  s.date        = '2016-11-29'
  s.summary     = "Cloudformation Stack"
  s.description = "Gem to create cloudformation stack"
  s.authors     = ["Vivek Dubey"]
  s.email       = 'vatsa.vivek@gmail.com'
  s.files       = ["lib/cloudformation_stack.rb"]
  s.add_runtime_dependency 'aws-sdk', '2.8.14'
  s.add_runtime_dependency 'rake', '10.4.2'
  s.add_runtime_dependency 'bundler', '> 1.10.6'
end
