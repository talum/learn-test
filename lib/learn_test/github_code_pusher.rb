require 'git'

module LearnTest
  class GithubCodePusher
    attr_reader :github_repo

    def initialize
      @github_repo = get_github_repo
    end

    def execute
      original_branch = github_repo.branch.name
      github_repo.branch(aaq_branch).checkout
      github_repo.add
      github_repo.commit(commit_message) if github_repo.status.changed.any?
      github_repo.push(remote = 'origin', branch = aaq_branch)
      previous_commit = github_repo.log[1].sha
      github_repo.reset(previous_commit)
      github_repo.checkout(original_branch)
    end

    private

    def get_github_repo
      Git.open(FileUtils.pwd)
    end

    def aaq_branch
      'aaq'
    end

    def commit_message
      'WIP'
    end

  end
end
