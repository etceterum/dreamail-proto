class OutRecipient < ActiveRecord::Base
  belongs_to :contact
  belongs_to :message, :class_name => 'OutMessage', :foreign_key => 'out_message_id'
end
