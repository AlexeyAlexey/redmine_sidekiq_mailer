class Sidekiq::Mailer::Worker
  include Sidekiq::Worker

  def perform(mailer_class, action, params)
    if defined?(RedmineApp)
      class_constant = "AfterFilter::#{self.class_name}".constantize
      if action_methods.include?(method_name.to_s) and class_constant.method_defined?(method_name.to_s)
        mailer_obj = class_constant.new
        params = mailer_obj.send(action, params)
        mailer_class.constantize.send(action, *params).deliver!
      end
    else
      mailer_class.constantize.send(action, *params).deliver!
    end
  end
end
