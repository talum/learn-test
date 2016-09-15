require 'yaml'

module LearnTest
  class Runner
    attr_reader :repo, :options
    SERVICE_URL = 'http://ironbroker-v2.flatironschool.com'

    def initialize(repo, options = {})
      @repo = repo
      @options = options
      die if !strategy
    end

    def run
      strategy.check_dependencies
      strategy.configure
      strategy.run
      if !help_option_present? && strategy.push_results? && !local_test_run?
        push_results(strategy)
      end
      strategy.cleanup unless keep_results?
      post_run_callbacks
    end

    def files
      @files ||= Dir.entries('.')
    end

    def keep_results?
      @keep_results ||= options[:keep] || !!options.delete('--keep')
    end

    def strategy
      @strategy ||= strategies.map{ |s| s.new(self) }.detect(&:detect)
    end

    private

    def post_run_callbacks
      learn_stats_path = "#{ENV['HOME']}/.learn-stats"
      if File.exists?(learn_stats_path)
        runs = File.read(learn_stats_path).to_i
        runs += 1
        f = File.open(learn_stats_path, "w")
        f.write(runs)
        f.close
      else
        runs = 1
        f = File.open(learn_stats_path, "w+")
        f.write(runs)
        f.close
      end

      return unless runs % 3 == 0

      puts <<-PROMPT

      /||
     //||
    // ||
   ||||||||||
       || //   Would you like to talk to a Learn Expert?
       ||//
       ||/

      PROMPT
      print '(y/n): '
      response = ''
      while(response.downcase != 'y' && response.downcase != 'n')
        response = gets.chomp
      end

      if response == 'y'
        `open https://qa.flatironschool.com/lessons/current?question_id=new`
      else
        puts 'Ok, happy learning!'
      end
    end

    def augment_results!(results)
      if File.exist?("#{FileUtils.pwd}/.learn")
        dot_learn = YAML.load(File.read("#{FileUtils.pwd}/.learn"))

        if !dot_learn['github'].nil?
          results[:github] = dot_learn['github']
        end
      end
    end

    def connection
      @connection ||= Faraday.new(url: SERVICE_URL) do |faraday|
        faraday.adapter  Faraday.default_adapter
      end
    end

    def strategies
      [
        LearnTest::Strategies::CSharpNunit,
        LearnTest::Strategies::Jasmine,
        LearnTest::Strategies::GreenOnion,
        LearnTest::Strategies::Rspec,
        LearnTest::Strategies::Karma,
        LearnTest::Strategies::Protractor,
        LearnTest::Strategies::JavaJunit,
        LearnTest::Strategies::Mocha,
        LearnTest::Strategies::PythonUnittest
      ]
    end

    def push_results(strategy)
      results = strategy.results
      augment_results!(results)

      begin
        connection.post do |req|
          req.url(strategy.service_endpoint)
          req.headers['Content-Type'] = 'application/json'
          req.body = Oj.dump(results, mode: :compat)
        end
      rescue Faraday::ConnectionFailed
        puts 'There was a problem connecting to Learn. Not pushing test results.'.red
      end
    end

    def help_option_present?
      options.include?('-h') || options.include?('--help')
    end

    def local_test_run?
      options.include?('-h') || options.include?('--local')
    end

    def die
      puts "This directory doesn't appear to have any specs in it."
      exit
    end
  end
end
