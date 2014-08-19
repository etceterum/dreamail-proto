class MessageController < ServiceController
  
  def announce
    
    # check recipients
    to_logins = input[Socketry::Proto::Message::TO_FIELD]
    bad_request unless to_logins.is_a?(Array) && !to_logins.empty?
    
    bad_to_logins = []
    contacts = []
    for login in to_logins
      bad_request unless login.is_a?(String)
      
      contact = user.contacts.find_by_login(login)
      if contact
        contacts << contact
      else
        bad_to_logins << login unless contact
      end
    end
    
    unless bad_to_logins.empty?
      output[Socketry::Proto::ERROR_FIELD] ||= {}
      output[Socketry::Proto::ERROR_FIELD][Socketry::Proto::Message::TO_FIELD] = bad_logins
      return
    end
    
    contacts.uniq!
    bad_request if contacts.empty?
    
    Announcement.transaction do
      # create an announcement
      announcement = node.announcements.create
    
      # and notices for each recipient
      for contact in contacts
        contact.notices.create(:announcement => announcement)
      end

      output[Socketry::Proto::Message::UID_FIELD] = announcement.uid
    end
    
  end
  
end
