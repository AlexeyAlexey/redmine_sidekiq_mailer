class Sidekiq::Mailer::Worker
  include Sidekiq::Worker

  def perform(mailer_class, action, params)
  	case action
  	  when "issue_add"
  	  	issue_add(mailer_class, action, params)
  	  	#issue, to_users, cc_users = *params

	    #issue_ = Issue.find_by_id("#{issue}")
        #to_users_ = to_users.map{|user_id| User.find_by_id("#{user_id}")}
	    #cc_users_ = cc_users.map{|user_id| User.find_by_id("#{user_id}")}
	      
	    #mailer_class.constantize.send(action, issue_, to_users_, cc_users_).deliver!
  		
      when "document_added"
      	document_added(mailer_class, action, params)
      	#document_id, user_current_id = *params
      	#document = Document.find_by_id(document_id)
      	#User.current = User.find_by_id(user_current_id)
      	#mailer_class.constantize.send(action, document).deliver!
  	end
    #mailer_class.constantize.send(action, *params).deliver!
  end

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
