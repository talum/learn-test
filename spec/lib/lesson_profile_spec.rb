require 'spec_helper'

describe LearnTest::LessonProfile do
  let!(:lesson_profile) do
    LearnTest::LessonProfile.new('test-repo', 'test-oauth-token')
  end

  let(:lesson_profile_payload) do
    { 'payload' => {
        'attributes' => {
          'lesson_id' => 0,
          'github_repository_id' => 0 }}}
  end

  let(:cli_event) {{ 'uuid' => 12345 }}

  before do
    allow(lesson_profile).to receive(:ignore_lesson_profile!).at_least(:once)
    allow(LearnTest::RepoParser).to receive(:get_repo).and_return('test-lesson')

    allow(lesson_profile).to receive(:request_data).and_return(lesson_profile_payload)

    @current_dir = Dir.pwd
    @tmp_lesson_dir = Dir.mktmpdir

    Dir.chdir(@tmp_lesson_dir)
  end

  it '#sync! sets the lesson_profile' do
    lesson_profile.sync!

    expect(lesson_profile.lesson_id).to eq lesson_profile_payload['payload']['attributes']['lesson_id']
    expect(lesson_profile.github_repository_id).to eq lesson_profile_payload['payload']['attributes']['github_repository_id']
    expect(lesson_profile.unacknowledged_cli_events).to be_kind_of(Array)
  end

  it '#add_processed_cli_event! adds an event to the processed cli events' do
    lesson_profile.sync!
    lesson_profile.add_processed_cli_event!(cli_event)
    expect(lesson_profile.processed_cli_events).to include(cli_event)
  end

  after do
    Dir.chdir(@current_dir)
    FileUtils.remove_entry(@tmp_lesson_dir)
  end
end
