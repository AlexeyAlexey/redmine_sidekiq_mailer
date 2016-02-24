require 'test_helper'

class BasicMailer < ActionMailer::Base
  include RedmineSidekiq::Mailer

  default :from => "from@example.org", :subject => "Subject"

  def welcome(to)
    mail(to: to) do |format|
      format.text { render :text => "Hello Mikel!" }
      format.html { render :text => "<h1>Hello Mikel!</h1>" }
    end
  end

  def hi(to, name)
    mail(to: to) do |format|
      format.text { render :text => "Hello Mikel!" }
      format.html { render :text => "<h1>Hello Mikel!</h1>" }
    end
  end
end

class MailerInAnotherQueue < ActionMailer::Base
  include RedmineSidekiq::Mailer
  sidekiq_options queue: 'priority', retry: 'false'

  default :from => "from@example.org", :subject => "Subject"

  def bye(to)
    mail(to: to)
  end
end

class PreventSomeEmails
  def self.delivering_email(message)
    if message.to.include?("foo@example.com")
      message.perform_deliveries = false
    end
  end
end

ActionMailer::Base.register_interceptor(PreventSomeEmails)

class RedmineSidekiqMailerTest < Test::Unit::TestCase
  def setup
    Object.send(:remove_const, :RedmineApp) if defined?(Object::RedmineApp)
    RedmineSidekiq::Mailer.excluded_environments = []
    ActionMailer::Base.deliveries.clear
    RedmineSidekiq::Mailer::Worker.jobs.clear
  end

  def test_queue_a_new_job
    BasicMailer.hi('test@example.com', 'Tester').deliver

    job_args = RedmineSidekiq::Mailer::Worker.jobs.first['args']
    expected_args = ['BasicMailer', 'hi', ['test@example.com', 'Tester']]
    assert_equal expected_args, job_args
  end

  def test_queues_at_mailer_queue_by_default
    BasicMailer.welcome('test@example.com').deliver
    assert_equal 'mailer', RedmineSidekiq::Mailer::Worker.jobs.first['queue']
  end

  def test_default_sidekiq_options
    BasicMailer.welcome('test@example.com').deliver
    assert_equal 'mailer', RedmineSidekiq::Mailer::Worker.jobs.first['queue']
    assert_equal true, RedmineSidekiq::Mailer::Worker.jobs.first['retry']
  end

  def test_enables_sidekiq_options_overriding
    MailerInAnotherQueue.bye('test@example.com').deliver
    assert_equal 'priority', RedmineSidekiq::Mailer::Worker.jobs.first['queue']
    assert_equal 'false', RedmineSidekiq::Mailer::Worker.jobs.first['retry']
  end

  def test_delivers_asynchronously
    BasicMailer.welcome('test@example.com').deliver
    assert_equal 1, RedmineSidekiq::Mailer::Worker.jobs.size
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_can_deliver_now
    BasicMailer.welcome('test@example.com').deliver!
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_really_delivers_email_when_performing_worker_job
    RedmineSidekiq::Mailer::Worker.new.perform('BasicMailer', 'welcome', 'test@example.com')
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_delivers_synchronously_if_running_in_a_excluded_environment
    RedmineSidekiq::Mailer.excluded_environments = [:test]
    BasicMailer.welcome('test@example.com').deliver
    assert_equal 0, RedmineSidekiq::Mailer::Worker.jobs.size
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_does_not_ignore_interceptors_when_delivering_synchronously
    BasicMailer.welcome('foo@example.com').deliver!
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_does_not_ignore_interceptors_when_delivering_asynchronously
    RedmineSidekiq::Mailer::Worker.new.perform('BasicMailer', 'welcome', 'foo@example.com')
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
end
