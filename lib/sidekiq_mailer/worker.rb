class Sidekiq::Mailer::Worker
  include Sidekiq::Worker

  def perform(mailer_class, action, params)
    mail_obj = mailer_class.constantize.send(:new)
    if mail_obj.send("sidekiq_mailer_filter_after").include?(action.to_s)#private_methods.include?(action.to_sym)
      #send(action, mailer_class, action, params)
      params = mail_obj.send("sidekiq_mailer_after_#{action}", params)
      perform_work(mailer_class, action, params)
    else
      mailer_class.constantize.send(action, *params).deliver!
    end
  end

  private
    def perform_work(mailer_class, action, params)
      mailer_class.constantize.send(action, *params).deliver!
    end
end
