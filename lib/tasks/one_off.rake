namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'fix git urls'
  task fix_git_urls: :environment do
    Project.where('repository_url LIKE ?', 'https://github.com/git+%').find_each do |p|
      p.repository_url.gsub!('https://github.com/git+', 'https://github.com/')
      p.save
    end
  end

  desc 'update user repos'
  task update_user_repos: :environment do
    User.find_each do |user|
      user.update_repo_permissions
      user.adminable_github_repositories.each{|g| g.update_all_info_async user.token }
    end
  end

  desc 'delete duplicate permissions'
  task delete_duplicate_permissions: :environment do
    perms = RepositoryPermission.select(:user_id, :github_repository_id).group(:user_id, :github_repository_id).having("count(*) > 1")

    perms.each do |perm|
      repo_perms = RepositoryPermission.where(github_repository_id: perm.github_repository_id, user_id: perm.user_id)

      repo_perms.each_with_index do |p, index|
        next if index.zero?
        p.destroy
      end
    end
  end
end
