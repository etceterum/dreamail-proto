class InMessagesController < ApplicationController
  include HumanHelper
  
  def index
    @messages = InMessage.received
    @message = @messages.first
  end
  
  def list
    @messages = InMessage.received.newest_first
    rows = []
    for message in @messages
      cells = [format_time(message.received_at), message.sender.login, message.subject]
      row = {
        :id => "ims#{message.id}",
        :cell => cells,
        :read => message.read?
      }
      rows << row
    end
    output = { :rows => rows }
    
    respond_to do |format|
      format.json do
        render :json => output.to_json
      end
    end
  end
  
  def show
    @message = InMessage.received.find(params[:id])
    @message.touch(:read_at) unless @message.read?
  end
  
  def embed
    @message = InMessage.received.find(params[:id])
    @message.touch(:read_at) unless @message.read?
    
    render :partial => 'show', :locals => { :message => @message }
  end
  
  def embed_content
    @message = InMessage.received.find(params[:id])
    render :layout => false
  end
  
  def header
    @message = InMessage.received.find(params[:id])
    render :partial => 'header', :locals => { :message => @message }
  end
  
end
