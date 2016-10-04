module LearnTest
  class CliEventProcessor
    def initialize(learn_profile, lesson_profile, results)
      @learn_profile  = learn_profile
      @lesson_profile = lesson_profile
      @prompter = InterventionPrompter.new(learn_profile, lesson_profile, results)
    end

    def execute
      unprocessed_cli_events.each { |event| process!(event) }
    end

    private

    attr_reader :lesson_profile, :prompter

    def process!(event)
      processed_cli_event!(event)
      prompter.ask_a_question
    end

    def processed_cli_event!(event)
      lesson_profile.add_processed_cli_event!(event)
    end

    def unprocessed_cli_events
      lesson_profile.unacknowledged_cli_events - lesson_profile.processed_cli_events
    end
  end
end
