module LearnTest
  class LearnProfile
    attr_reader :oauth_token

    PROFILE_PATH = "#{ENV['HOME']}/.learn_profile"

    def initialize(oauth_token)
      @oauth_token = oauth_token
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

    def learn_api_client
      @learn_api_client ||= LearnApi::Client.new(oauth_token)
    end

    def request_profile
      learn_api_client.get_learn_profile
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
