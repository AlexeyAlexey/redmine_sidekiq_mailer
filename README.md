 #Решаемая задача

    Конвертировать объекты передаваемые в очередь в допустимый формат и затем конвертировать обратно в объекты передаваемые в асинхронно исполняемый метод


Методы объявленные в модуле с окончанием ArgsConverterSidekiq могут изменять параметры передаваемые в очередь

Методы объявленные в модуле с окончанием ExtSidekiq могут изменять параметры считываемые из очереди и затем передавать в метод для исполнения

Модуль с окончанием ArgsConverterSidekiq должен быть включен в класс Sidekiq::Mailer::Worker (Sidekiq::Mailer::Worker.send(:include, RedmineMailerExtSidekiq) )

Модуль с окончанием ExtSidekiq должен быть включен в модуль Sidekiq::Mailer::Proxy (  Sidekiq::Mailer::Proxy.send(:include, RedmineMailerArgsConverterSidekiq)  )


Методы в модулях должны именоваться также как и асинхронно исполняемые методы

Методы в модулях с окончаниями ArgsConverterSidekiq и ExtSidekiq должны быть объявлены как private

Например, если в метод для отправки письма передается объект то перед отправкой задачи в очередь объект можно сериализовать, а после считывания из очереди но перед исполнением задачи десериализовать или если это запись из БД то можно перед отправкой задачи в очередь передать id записи, а после считывания из очереди но перед исполнением восстановить объект запросом к БД


Асинхронно будут исполняться только методы объявленные в модуле с окончанием ExtSidekiq

DATABASE_URL='mysql2://redmine_clear:@localhost/redmine_clear_development' bundle exec sidekiq -e development -q mailer

Modify sidekiq_mailer (http://github.com/andersondias/sidekiq_mailer) for redmine 

Дает возможность модифицировать праметры до добавления в очередь и после извлечения из очереди до исполнения метода

#####
## Example Redmine
#####
    ActionDispatch::Callbacks.to_prepare do
      Mailer.send(:include, Sidekiq::Mailer)



      module RedmineMailerExtSidekiq
        private
            def issue_add(mailer_class, action, params)
              issue, to_users, cc_users = *params
              issue_ = Issue.find_by_id("#{issue}")
            to_users_ = to_users.map{|user_id| User.find_by_id("#{user_id}")}
              cc_users_ = cc_users.map{|user_id| User.find_by_id("#{user_id}")}
            
                params = []
            params << issue_
            params << to_users_
            params << cc_users_
              perform_work(mailer_class, action, params)
          end

          def document_added(mailer_class, action, params)
            document_id, user_current_id = *params
            document = Document.find_by_id(document_id)
            User.current = User.find_by_id(user_current_id)
            mailer_class.constantize.send(action, document).deliver!

            params = []
            params << document
            perform_work(mailer_class, action, params)
          end

      end

      module RedmineMailerArgsConverterSidekiq
        private
            def issue_add(args)
            args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (a.id)}
          end

          def document_added(args)
            [args.first.id, User.current.id]
          end

      end
      Sidekiq::Mailer::Worker.send(:include, RedmineMailerExtSidekiq)
      Sidekiq::Mailer::Proxy.send(:include, RedmineMailerArgsConverterSidekiq)

    end



#####
## 
#####






# Sidekiq::Mailer

Sidekiq::Mailer adds to your ActionMailer classes the ability to send mails asynchronously.

## Usage

If you want to make a specific mailer to work asynchronously just include Sidekiq::Mailer module:

    class MyMailer < ActionMailer::Base
      include Sidekiq::Mailer

      def welcome(to)
        ...
      end
    end

Now every deliver you make with MyMailer will be asynchronous.

    # Queues the mail to be sent asynchronously by sidekiq
    MyMailer.welcome('your@email.com').deliver

The default queue used by Sidekiq::Mailer is 'mailer'. So, in order to send mails with sidekiq you need to start a worker using:

    sidekiq -q mailer

If you want to skip sidekiq you should use the 'deliver!' method:

    # Mail will skip sidekiq and will be sent synchronously
    MyMailer.welcome('your@email.com').deliver!

By default Sidekiq::Mailer will retry to send an email if it failed. But you can [override sidekiq options](https://github.com/andersondias/sidekiq_mailer/wiki/Overriding-sidekiq-options) in your mailer.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq_mailer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_mailer

## Testing

Delayed e-mails is an awesome thing in production environments, but for e-mail specs/tests in testing environments it can be a mess causing specs/tests to fail because the e-mail haven't been sent directly. Therefore you can configure what environments that should be excluded like so:

    # config/initializers/sidekiq_mailer.rb
    Sidekiq::Mailer.excluded_environments = [:test, :cucumber]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
