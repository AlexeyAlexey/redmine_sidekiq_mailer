require_dependency 'sidekiq_mailer'

ActionDispatch::Callbacks.to_prepare do
  Mailer.send(:include, Sidekiq::Mailer)



  module RedmineMailerExtSidekiq
    private
	    def issue_add(mailer_class, action, params)
        #sleep 1
        i = 0
        issue_ = nil
	      issue_id, to_users, cc_users = *params
        #while issue_.nil? and i < 100
        #  i += 1
        #  issue_ = Issue.find_by_id(issue_id)
        #end

        to_users_ = to_users.map{|user_id| User.find_by_id(user_id)}
	      cc_users_ = cc_users.map{|user_id| User.find_by_id(user_id)}
		    params_ = []
        params_ << issue_
        params_ << to_users_
        params_ << cc_users_
    
	      perform_work(mailer_class, action, params_)
      end

      def document_added(mailer_class, action, params)
        document_id, user_current_id = *params
        document = Document.find_by_id(document_id)
        User.current = User.find_by_id(user_current_id)

        params = []
        params << document
        perform_work(mailer_class, action, params)
      end

  end

  module RedmineMailerArgsConverterSidekiq
    
    private
	    def issue_add(args)
        args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (a.id)}
        #args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (Marshal.dump(a))}
      end

      def document_added(args)
        [args.first.id, User.current.id]
      end

  end


  
  module RedmineMailerFilters
    #SIDEKIQ_MAILER_FILTER_ONLY = ["issue_add"]
    #SIDEKIQ_MAILER_FILTER_BEFORE = ["issue_add"]
    #SIDEKIQ_MAILER_FILTER_AFTER = ["issue_add"]
    private
      def sidekiq_mailer_before_issue_add(args)
        args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (a.reload.id)}
        #args.map{|a| a.is_a?(Array) ? (a.map(&:id))  : (Marshal.dump(a))}
      end

      def sidekiq_mailer_before_document_added(args)
        [args.first.id, User.current.id]
      end

      def sidekiq_mailer_after_issue_add(params)
        #sleep 1
        i = 0
        issue_ = nil
        issue_id, to_users, cc_users = *params
        while issue_.nil? and i < 100
          i += 1
          issue_ = Issue.find_by_id(issue_id)
        end

        to_users_ = to_users.map{|user_id| User.find_by_id(user_id)}
        cc_users_ = cc_users.map{|user_id| User.find_by_id(user_id)}
        params = []
        params << issue_
        params << to_users_
        params << cc_users_
        params
        #perform_work(mailer_class, action, params_)
      end

      def sidekiq_mailer_after_document_added(params)
        document_id, user_current_id = *params
        document = Document.find_by_id(document_id)
        User.current = User.find_by_id(user_current_id)

        params = []
        params << document
        params
        #perform_work(mailer_class, action, params)
      end

      #SIDEKIQ_MAILER_FILTER_ONLY = ["issue_add"]
      def sidekiq_mailer_filter_only
        ["issue_add"]
      end

      def sidekiq_mailer_filter_before
        ["issue_add"]
      end

      def sidekiq_mailer_filter_after
        ["issue_add"]
      end

  end
  Mailer.send(:include, RedmineMailerFilters)

  #Sidekiq::Mailer::Worker.send(:include, RedmineMailerExtSidekiq)
  Sidekiq::Mailer::Proxy.send(:include, RedmineMailerArgsConverterSidekiq)

end
