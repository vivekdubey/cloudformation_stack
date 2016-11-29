base_directory = File.expand_path('../',File.dirname(__FILE__))
Dir.glob("#{base_directory}/helper/*.rb").each { |file| require file }
Dir.glob("#{base_directory}/helper/*.rb").each { |file| puts file }
Dir.glob("#{base_directory}/cloudformation_stack/*.rb").each { |file| require file }
Dir.glob("#{base_directory}/services/*.rb").each { |file| require file }
Dir.glob("#{base_directory}/rake/*.rake").each { |file| load file }
