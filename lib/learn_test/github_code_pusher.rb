require 'git'

module LearnTest
  class GithubCodePusher

    def self.execute
      g = Git.open(FileUtils.pwd)
      g.branch('master').checkout
      g.add
      g.commit('WIP') if g.status.changed.any?
      g.push
    end
  end
end
