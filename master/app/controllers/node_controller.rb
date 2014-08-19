class NodeController < ServiceController
  ##########

  before_filter :ensure_existing_user
  before_filter :ensure_existing_node, :except => :new

  ##########
  
  def new
    bad_request unless node.new_record?
    public_key = input[Proto::Node::PUBLIC_KEY_FIELD]
    bad_request unless public_key
    node.public_key = public_key
    node.save or bad_identity
    output[Proto::Node::UID_FIELD] = node.uid
  end
  
  def update
    ####################
    # read-only part: we do not update any data here
    
    # track the whereabouts of the node
    reported_host = input[Proto::Node::HOST_FIELD]
    reported_port = input[Proto::Node::PORT_FIELD]
    bad_request if reported_port && (!reported_port.is_a?(Fixnum) || reported_port <= 0)
    
    # check and normalize the 'since' field
    since = input[Proto::SINCE_FIELD]
    bad_request if since && !since.is_a?(Time)
    first_time = !since
    since = node.created_at if !since || since < node.created_at

    # TODO: handle contacts better: need to report added and removed separately
    # since the 'since' time, but if the 'since' value received from the node is nil,
    # need to get all current user's contacts and put them into the 'added' field
    # for now, always reporting all current user's contact in the 'added' field
    output[Proto::Master::CONTACTS_FIELD] = {}
    new_contact_logins = user.contacts.collect(&:login)
    output[Proto::Master::CONTACTS_FIELD][Proto::ADD_FIELD] = new_contact_logins
    output[Proto::Master::CONTACTS_FIELD][Proto::REMOVE_FIELD] = []
    
    ##########
    # process message responses aka sent messages
    
    message_responses = input[:message_responses]
    bad_request unless message_responses && message_responses.is_a?(Array)
    for message_response in message_responses
      
      auth = message_response[:auth]
      bad_request unless auth && auth.is_a?(String)

      data = message_response[:data]
      bad_request unless data && data.is_a?(String)

      announcement_uid = message_response[:announcement]
      bad_request unless announcement_uid && announcement_uid.is_a?(String)
      announcement = node.announcements.find_by_uid(announcement_uid)
      unless announcement
        logger.error "Unknown announcement uid \"#{announcement_uid}\" in message response, ignoring"
        next
      end
      
      receiver_node_uid = message_response[:receiver]
      bad_request unless receiver_node_uid && receiver_node_uid.is_a?(String)
      receiver_node = Node.find_by_uid(receiver_node_uid)
      unless receiver_node
        logger.error "Unknown receiver node uid \"#{receiver_node_uid}\" in message response, ignoring"
        next
      end
      receiver_user = receiver_node.user
      unless user.connected_with?(receiver_user)
        logger.error "Receiver user \"#{receiver_user.login}\" is not user's contact, ignoring"
        next
      end
      
      message = receiver_node.messages.not_sent.find(
        :first,
        :joins => [{ :notice => :announcement }],
        :conditions => ['announcements.id = ?', announcement.id]
      )
      unless message
        logger.error "Could not locate message for message response, ignoring"
        next
      end
      unless message.auth.blank?
        logger.error "Message auth data for message response is not blank, ignoring"
        next
      end
      unless message.data.blank?
        logger.error "Message data for message response is not blank, ignoring"
        next
      end
      
      message.auth = auth
      message.data = data
      message.touch(:sent_at)
      
    end

    ##########
    # get notices ordered by id that satisfy all of the following criteria:
    # - belong to our user
    # - created after 'since' time
    # - have no message for our node
    
    notices_without_message_for_node = user.notices.newer_than(since).scoped({
      :include => [{ :user => :nodes }, :messages],
      :conditions => ['nodes.id = ? and messages.id is null', node.id]
    }).ordered
    
    ##########
    # get outstanding message requests for us, using the following criteria:
    # - Message exists but is not sent
    # - Message results from one of our node's announcements
    # - Message belongs to a user who is on the contact list of our user
    
    messages_for_node = Message.not_sent.scoped({
      :joins => [{ :notice => { :announcement => :node } }],
      :conditions => ['nodes.id = ?', node.id]
    }).ordered
    
    message_requests = []
    for message in messages_for_node
      next unless user.connected_with?(message.node.user)
      message_request = {
        :announcement   => message.announcement.uid,
        :receiver => {
          :user => message.user.login,
          :node => {
            :uid => message.node.uid,
            :public_key => message.node.public_key
          }
        }
      }
      message_requests << message_request
    end
    output[:message_requests] = message_requests
    
    ##########
    # process message receipts and mark messages as received
    
    message_receipts = input[:message_receipts]
    bad_request unless message_receipts && message_receipts.is_a?(Array)
    for announcement_uid in message_receipts
      bad_request unless announcement_uid.is_a?(String)
      announcement = Announcement.find_by_uid(announcement_uid)
      unless announcement
        logger.error "Unknown announcement UID \"#{announcement_uid}\" in message receipts, ignoring"
        next
      end
      notice = announcement.notices.find_by_user_id(user.id)
      unless notice
        logger.error "Announcement \"#{announcement_uid}\" doesn't have a notice for user #{user.login}, ignoring"
        next
      end
      message = notice.messages.find_by_node_id(node.id)
      unless message
        logger.error "Announcement \"#{announcement_uid}\" doesn't have a message for node #{node.uid}, ignoring"
        next
      end
      if message.confirmed?
        logger.error "Message #{message.id} is already confirmed, ignoring"
        next
      end
      message.touch(:confirmed_at)
    end

    ##########
    # forward sent but not confirmed messages to the node
    
    output[:messages] = []
    node.messages.sent.not_confirmed.ordered.each do |message|
      announcement = message.notice.announcement
      message_data = {
        :uid => announcement.uid,
        :from => announcement.node.user.login,
        :sent_at => announcement.created_at,
        :auth => message.auth,
        :data => message.data
      }
      output[:messages] << message_data
    end

    ##########
    
    # # user.notices.created_since(since).
    # 
    # # get all in-messages for our user created after 'since' time, 
    # # for which our node doesn't have a head - we'll need to create missing heads
    # # TODO: add a clause to only select if the sender user is a current contact
    # # TODO: add a 'since' clause
    # in_messages_without_head = InMessage.find(
    #   :all,
    #   :include => [{ :user => :nodes }, :heads],
    #   :conditions => ['users.id = ? and nodes.id = ? and in_message_heads.id is null', user.id, node.id]
    # )
    # 
    # # get all head requests without data for our out-messages
    # heads_without_data = InMessageHead.find(
    #   :all,
    #   :joins => [{ :message => [{ :user => :reverse_connections }, { :out_message => :node }]}],
    #   :conditions => ['in_message_heads.data is null and nodes.id = ? and connections.user_id = ?', node.id, user.id]
    # )

    ####################
    # write part: we update all data here
    
    node.reported_host = reported_host
    node.reported_port = reported_port
    node.detected_host = request.remote_ip

    # commit
    Node.transaction do
      # touch the node to record the ping time
      node.touch
      
      # create missing messages
      for notice in notices_without_message_for_node
        notice.messages.create(:node => node)
      end
      
    end
    
  end
  
  ##########
end
