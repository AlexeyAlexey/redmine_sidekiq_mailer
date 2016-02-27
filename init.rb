ActionDispatch::Callbacks.to_prepare do
  Mailer.send(:include, Sidekiq::RedmineMailer)
  require_dependency 'redmine_sidekiq_mailer/filters/mailer'
end


Redmine::Plugin.register :redmine_sidekiq_mailer do
  name 'Sidekiq Mailer Integration'
  author 'Alexey Kondratenko'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/AlexeyAlexey/redmine_sidekiq_mailer'
  author_url 'https://github.com/AlexeyAlexey/redmine_sidekiq_mailer'
  
end


