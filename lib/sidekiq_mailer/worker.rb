class Sidekiq::Mailer::Worker
  include Sidekiq::Worker

  def perform(mailer_class, action, params)
    if private_methods.include?(action.to_sym)
      send(action, mailer_class, action, params)
    else
      mailer_class.constantize.send(action, *params).deliver!
    end
  end

 
end
