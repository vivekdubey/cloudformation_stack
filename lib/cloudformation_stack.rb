Dir.glob("#{base_directory}/lib/cloudformation_stack/*.rb").each { |file| require file }
Dir.glob("#{base_directory}/services/*.rb").each { |file| require file }
