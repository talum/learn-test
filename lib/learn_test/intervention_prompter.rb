require 'socket'

module LearnTest
  class InterventionPrompter
    BASE_URL = 'https://qa.learn.flatironschool.com'

    attr_reader :results, :repo, :token, :learn_profile

    def initialize(test_results, repo, token, learn_profile)
      @results = test_results
      @repo = repo
      @token = token
      @learn_profile = learn_profile
      @lesson_profile = LessonProfile.new(repo, token)
    end

    def execute
      unprocessed_cli_events.each do |event|
        processed_cli_event!(event)
        ask_a_question
      end
    end

    private

    attr_reader :lesson_profile

    def processed_cli_event!(event)
      lesson_profile.add_processed_cli_event!(event)
    end

    def unprocessed_cli_events
      lesson_profile.unacknowledged_cli_events - lesson_profile.processed_cli_events
    end

    def ask_a_question
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
        browser_open(ask_a_question_url)
      else
        puts "No problem. You got this."
      end
    end

    def base_url
      BASE_URL
    end

    def ask_a_question_url
      lesson_id = lesson_profile.lesson_id
      uuid = lesson_profile.cli_event_uuid

      base_url + "/lessons/#{lesson_id}?question_id=new&cli_event=#{uuid}"
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
