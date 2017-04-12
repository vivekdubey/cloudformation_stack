class Log
  class << self
    def info(*messages)
      messages.each { |message| puts "#{Constants::GREEN_COLOR}[Info] #{message}#{Constants::RESET_COLOR}" }
    end

    def warn(*messages)
      messages.each { |message| puts "#{Constants::BLUE_COLOR}[Warning] #{message} #{Constants::RESET_COLOR}" }
    end

    def error(*messages)
      messages.each { |message| puts "#{Constants::RED_COLOR}[Error!] #{message}#{Constants::RESET_COLOR}" }
      exit 1
    end

    def success(*messages)
      messages.each { |message| puts "#{Constants::YELLOW_COLOR}[Hurray!] #{message}#{Constants::RESET_COLOR}" }
    end

    def error_and_continue(*messages)
      messages.each { |message| puts "#{Constants::PURPLE_COLOUR}[Error!] #{message}#{Constants::RESET_COLOR}" }
    end
  end
end
