class Sidekiq::Mailer::Proxy
  delegate :to_s, :to => :actual_message

  def initialize(mailer_class, method_name, *args)
    @mailer_class = mailer_class
    @method_name = method_name
    unless Sidekiq.server?
      modules_with_methods = Sidekiq::Mailer::Proxy.included_modules.select{|m| "#{m}"=~/\wArgsConverterSidekiq/}
      methods_from_modules = modules_with_methods.map(&:private_instance_methods).flatten
      if methods_from_modules.include?(method_name)
         *@args = send(method_name, args)
      end
    else
      *@args = *args
    end
  end

  def actual_message
    @actual_message ||= @mailer_class.send(:new, @method_name, *@args).message
  end

  def deliver
    return deliver! if Sidekiq::Mailer.excludes_current_environment?
    Sidekiq::Mailer::Worker.client_push(to_sidekiq)
  end

  def excluded_environment?
    Sidekiq::Mailer.excludes_current_environment?
  end

  def deliver!
    actual_message.deliver
  end

  def method_missing(method_name, *args)
    actual_message.send(method_name, *args)
  end

  def to_sidekiq
    params = {
      'class' => Sidekiq::Mailer::Worker,
      'args' => [@mailer_class.to_s, @method_name, @args]
    }
    params.merge(@mailer_class.get_sidekiq_options)
  end
end
