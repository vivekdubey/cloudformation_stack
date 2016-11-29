# base_directory = File.expand_path('.',File.dirname(__FILE__))
Dir.glob("../helper/*.rb").each { |file| require file }
Dir.glob("cloudformation_stack/*.rb").each { |file| require file }
Dir.glob("../services/*.rb").each { |file| require file }
Dir.glob("../rake/*.rake").each { |file| load file }
