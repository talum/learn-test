module LearnTest
  class LearnProfile
    attr_reader :token
    PROFILE_PATH = "#{ENV['HOME']}/.learn_profile"
    BASE_URL = "http://localhost:3000"
    PROFILE_ENDPOINT = "/api/cli/profile.json"

    def initialize(token)
      @token = token
    end

    def aaq_active?
      profile = read_profile
      profile["features"]["aaq_intervention"] == true
    end

    def sync!
      if needs_update?
        profile = request_profile
        write(profile)
      end
    end

    private

    def needs_update?
      profile = read_profile
      profile["generated_at"].to_i < one_day_ago
    end

    def one_day_ago
      (Time.now.to_i - 86400)
    end

    def read_profile
      if File.exists?(profile_path)
        begin
          JSON.parse(File.read(profile_path))
        rescue JSON::ParserError
          default_payload
        end
      else
        default_payload
      end
    end

    def write(profile)
      f = File.open(profile_path, 'w+')
      f.write(profile.to_json)
      f.close
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.adapter(Faraday.default_adapter)
      end
    end

    def request_profile
      begin
        response = connection.get do |req|
          req.url(PROFILE_ENDPOINT)
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{token}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError, Faraday::ConnectionFailed
        default_payload
      end
    end

    def default_payload
      { "features" => 
        {
          "aaq_intervention" => false
        },
        "generated_at" => 0
      }
    end

    def profile_path
      PROFILE_PATH
    end

  end
end
