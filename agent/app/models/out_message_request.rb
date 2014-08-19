class OutMessageRequest < ActiveRecord::Base
  belongs_to  :message, :class_name => 'OutMessage', :foreign_key => 'out_message_id'
  belongs_to  :contact
end
