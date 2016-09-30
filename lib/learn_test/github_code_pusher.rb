require 'git'

module LearnTest
  class GithubCodePusher

    def self.execute
      g = Git.open(FileUtils.pwd)
      g.branch('master').checkout
      g.add
      g.commit('WIP')
      g.push
    end
  end
end
