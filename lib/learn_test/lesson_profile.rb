module LearnTest
  class LessonProfile
    LESSON_PROFILE_FILENAME = '.lesson_profile'
    BASE_URL = 'https://qa.learn.flatironschool.com'
    PROMPT_ENDPOINT = "/api/cli/lesson_profile.json"

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
      payload = request_data['payload']

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

    def request_data
      begin
        response = connection.get do |req|
          req.url(intervention_url)
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{oauth_token}"
        end

        JSON.parse(response.body)
      rescue Faraday::ConnectionFailed
        nil
      end
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |faraday|
        faraday.adapter(Faraday.default_adapter)
      end
    end

    def intervention_url
      processed_event_param = processed_cli_events.map { |e| "pce[]=#{e['uuid']}" }.join('&')
      processed_event_param.prepend('&') if processed_event_param.length > 0

      prompt_endpoint + "?repo_name=#{repo_name}#{processed_event_param}"
    end

    def base_url
      BASE_URL
    end

    def prompt_endpoint
      PROMPT_ENDPOINT
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
        JSON.parse(File.read(lesson_profile_path))
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
