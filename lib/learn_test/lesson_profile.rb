module LearnTest
  class LessonProfile
    LESSON_PROFILE_FILENAME = '.lesson_profile'

    def initialize(repo_name, oauth_token)
      @repo_name = repo_name
      @oauth_token = oauth_token
    end

    def lesson_id
      attributes['lesson_id']
    end

    def github_repository_id
      attributes['github_repository_id']
    end

    def unacknowledged_cli_events
      Array(attributes['unacknowledged_cli_events'])
    end

    def processed_cli_events
      Array(attributes['processed_cli_events'])
    end

    def add_processed_cli_event!(event)
      attributes['processed_cli_events'] ||= []
      attributes['processed_cli_events'] << event
      attributes['processed_cli_events'].uniq!

      write!
    end

    def sync!
      payload = request_data && request_data['payload']

      unless payload.nil? || payload['attributes'].nil?
        payload_attrs = payload.fetch('attributes')

        attributes['lesson_id'] = payload_attrs['lesson_id']
        attributes['github_repository_id'] = payload_attrs['github_repository_id']
        attributes['unacknowledged_cli_events'] = Array(payload_attrs['unacknowledged_cli_events'])

        write!
      end
    end

    private

    attr_accessor :data
    attr_reader :repo_name, :oauth_token

    def learn_api_client
      @learn_api_client ||= LearnApi::Client.new(oauth_token)
    end

    def request_data
      learn_api_client.lesson_profile_sync(repo_name, processed_cli_events)
    end

    def lesson_profile_path
      LESSON_PROFILE_PATH
    end

    def lesson_profile_path
      path = ENV['LESSON_PROFILE_PATH'] || Dir.pwd
      "#{path}/#{lesson_profile_filename}"
    end

    def lesson_profile_filename
      LESSON_PROFILE_FILENAME
    end

    def data
      @data ||= read
    end

    def attributes
      data['attributes'] ||= {}
      data['attributes']
    end

    def write!
      ignore_lesson_profile!

      f = File.open(lesson_profile_path, 'w+')
      f.write(data.to_json)
      f.close
    end

    def read
      if File.exists?(lesson_profile_path)
        begin
          JSON.parse(File.read(lesson_profile_path))
        rescue JSON::ParserError
          new_profile
        end
      else
        new_profile
      end
    end

    def new_profile
      { 'attributes' => {} }
    end

    def ignore_lesson_profile!
      File.open('.git/info/exclude', 'a+') do |f|
        contents = f.read
        unless contents.match(/\.lesson_profile/)
          f.puts('.lesson_profile')
        end
      end
    end
  end
end
