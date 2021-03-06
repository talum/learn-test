require 'spec_helper'

describe LearnTest::InterventionPrompter do
  let(:learn_profile)  { LearnTest::LearnProfile.new('test-oauth-token') }
  let(:lesson_profile) { LearnTest::LessonProfile.new('test-repo', 'test-oauth-token') }
  let(:results) { Hash.new }

  let (:intervention_prompter) do
    LearnTest::InterventionPrompter.new(learn_profile, lesson_profile, results)
  end

  describe '#ask_a_question_should_trigger?' do
    context 'when it is on a native windows environment' do
      it 'returns false' do
        allow_any_instance_of(LearnTest::InterventionPrompter).to receive(:windows_environment?).and_return(true)

        expect(intervention_prompter.send(:ask_a_question_should_trigger?)).to eq(false)
      end
    end

    context 'when all the tests are passing' do
      it 'returns false' do
        allow_any_instance_of(LearnTest::InterventionPrompter).to receive(:all_tests_passing?).and_return(true)

        expect(intervention_prompter.send(:ask_a_question_should_trigger?)).to eq(false)
      end
    end

    context 'when the lesson profile returns that aaq should trigger' do
      it 'returns true' do
        allow_any_instance_of(LearnTest::InterventionPrompter).to receive(:windows_environment?).and_return(false)
        allow_any_instance_of(LearnTest::InterventionPrompter).to receive(:all_tests_passing?).and_return(false)
        allow(learn_profile).to receive(:aaq_active?).and_return(true)

        expect(intervention_prompter.send(:ask_a_question_should_trigger?)).to eq(true)
      end
    end

    after do
      profile_path = "#{ENV['HOME']}/.learn_profile"
      FileUtils.remove_file(profile_path) if File.exist?(profile_path)
    end
  end
end
