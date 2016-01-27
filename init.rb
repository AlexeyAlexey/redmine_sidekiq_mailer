require_dependency 'sidekiq_mailer'

ActionDispatch::Callbacks.to_prepare do
  Mailer.send(:include, Sidekiq::Mailer)



  module RedmineMailerExtSidekiq
    private
	  def issue_add(mailer_class, action, params)
	    issue, to_users, cc_users = *params
	    issue_ = Issue.find_by_id("#{issue}")
        to_users_ = to_users.map{|user_id| User.find_by_id("#{user_id}")}
	    cc_users_ = cc_users.map{|user_id| User.find_by_id("#{user_id}")}
		      
	    mailer_class.constantize.send(action, issue_, to_users_, cc_users_).deliver!

      end

      def document_added(mailer_class, action, params)
        document_id, user_current_id = *params
        document = Document.find_by_id(document_id)
        User.current = User.find_by_id(user_current_id)
        mailer_class.constantize.send(action, document).deliver!
      end

  end

  module RedmineMailerArgsConverterSidekiq
    private
	  def issue_add(args)
        args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (a.id)}
      end

      def document_added(args)
        *@args = [args.first.id, User.current.id]
      end

  end
  Sidekiq::Mailer::Worker.send(:include, RedmineMailerExtSidekiq)
  Sidekiq::Mailer::Proxy.send(:include, RedmineMailerArgsConverterSidekiq)

end
