module LearnTest::LearnApi
  class Client
    LEARN_API_URL = 'https://learn.co'

    def initialize(oauth_token)
      @oauth_token = oauth_token
    end

    def get_learn_profile
      get('/api/cli/profile.json')
    end

    def lesson_profile_sync(repo_name, processed_cli_events)
      processed_event_param = processed_cli_events.map { |e| "pce[]=#{e['uuid']}" }.join('&')
      processed_event_param.prepend('&') if processed_event_param.length > 0

      get("/api/cli/lesson_profile.json?repo_name=#{repo_name}#{processed_event_param}")
    end

    private

    attr_reader :oauth_token

    def get(path)
      begin
        response = connection.get do |req|
          req.url(path)
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{oauth_token}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError, Faraday::ConnectionFailed
        nil
      end
    end

    def connection
      @connection ||= Faraday.new(url: learn_api_url) do |faraday|
        faraday.adapter(Faraday.default_adapter)
      end
    end

    def learn_api_url
      ENV['LEARN_API_URL'] || LEARN_API_URL
    end
  end
end
