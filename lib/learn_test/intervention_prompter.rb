require 'socket'

module LearnTest
  class InterventionPrompter
    LEARN_API_URL = 'https://learn.co'

    def initialize(learn_profile, lesson_profile, results)
      @results = results
      @learn_profile  = learn_profile
      @lesson_profile = lesson_profile
    end

    def ask_a_question(cli_event_uuid)
      return false unless ask_a_question_should_trigger?

      response = ''
      until response == 'y' || response == 'n'
        puts <<-PROMPT
   /||
  //||
  // ||
  ||||||||||
    || //    Stuck on this Lab and want some help from an Expert?
    ||//
    ||/
   PROMPT
      print 'Enter (Y/n): '
      response = STDIN.gets.chomp.downcase
      end

      if response == 'y'
        puts "Good move. An Expert will be with you shortly on Ask a Question."
        browser_open(ask_a_question_url(cli_event_uuid))
      else
        puts "No problem. You got this."
      end
    end

    private

    attr_reader :results, :learn_profile, :lesson_profile

    def learn_api_url
      ENV['LEARN_API_URL'] || LEARN_API_URL
    end

    def ask_a_question_url(cli_event_uuid)
      lesson_id = lesson_profile.lesson_id
      uuid = cli_event_uuid

      learn_api_url + "/lessons/#{lesson_id}?question_id=new&cli_event=#{uuid}"
    end

    def ask_a_question_should_trigger?
      return false unless learn_profile.aaq_active?
      return false if windows_environment? || all_tests_passing?

      true
    end

    def all_tests_passing?
      results[:failure_count] == 0
    end

    def browser_open(url)
      if ide_environment?
        ide_client.browser_open(url)
      elsif linux_environment?
        `xdg-open "#{url}"`
      else
        `open "#{url}"`
      end
    end

    def ide_client
      @ide_client ||= LearnTest::Ide::Client.new
    end

    def ide_environment?
      Socket.gethostname.end_with? '.students.learn.co'
    end

    def linux_environment?
      !!RUBY_PLATFORM.match(/linux/)
    end

    def windows_environment?
      !!RUBY_PLATFORM.match(/mswin|mingw|cygwin/)
    end
  end
end
