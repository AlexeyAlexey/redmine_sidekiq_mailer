require_dependency 'sidekiq_mailer'

ActionDispatch::Callbacks.to_prepare do
  Mailer.send(:include, Sidekiq::Mailer)
end
