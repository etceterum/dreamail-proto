class OutMessagesController < HumanController
  include ActionView::Helpers::NumberHelper

  def drafts
    @out_messages = OutMessage.drafts
  end
  
  def unsent
    @out_messages = OutMessage.unsent
  end
  
  def sent
    @out_messages = OutMessage.sent
  end
  
  def embed_draft
    @out_message = OutMessage.drafts.find(params[:id])
    render :partial => 'show', :locals => { :message => @out_message }
  end
  
  # def embed_draft_content
  #   @out_message = OutMessage.drafts.find(params[:id])
  #   render :layout => false
  # end
  
  def unsent_list
    @messages = OutMessage.unsent
    rows = []
    for message in @messages
      size = message.attachments.inject(0) { |size, a| size + a.size }
      cells = [number_to_human_size(size), message.recipients.collect { |r| r.contact.login }.join('; '), message.subject]
      row = {
        :id => "ims#{message.id}",
        :cell => cells
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
  
  def sent_list
    @messages = OutMessage.sent
    rows = []
    for message in @messages
      size = message.attachments.inject(0) { |size, a| size + a.size }
      cells = [number_to_human_size(size), message.recipients.collect { |r| r.contact.login }.join('; '), message.subject]
      row = {
        :id => "ims#{message.id}",
        :cell => cells
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
  
  def embed
    @out_message = OutMessage.find(params[:id])
    render :partial => 'show', :locals => { :message => @out_message }
  end
  
  def embed_content
    @out_message = OutMessage.find(params[:id])
    render :layout => false
  end
  
  def new
    @out_message = OutMessage.new(params[:message])
  end
  
  def create
    @out_message = OutMessage.new(params[:out_message])
    if @out_message.save
      post_process(:create, @out_message, !params[:send_message].blank?)
      # flash[:notice] = "Successfully created message."
      # redirect_to :action => :edit, :id => @out_message.id
    else
      render :action => 'new'
    end
  end
  
  def edit
    @out_message = OutMessage.drafts.find(params[:id])
  end
  
  def update
    # render :text => params.inspect
    # return
    @out_message = OutMessage.drafts.find(params[:id])
    if @out_message.update_attributes(params[:out_message])
      post_process(:update, @out_message, !params[:send_message].blank?)
      # flash[:notice] = "Successfully updated message."
      # redirect_to :action => :edit
    else
      render :action => 'edit'
    end
  end
  
  private
  
  def post_process(what, message, to_send)
    if to_send
      raise "Not a draft" unless message.draft?
      raise "No recipients" unless message.has_recipients?
      raise "No subject" if message.subject.blank?
      raise "No attachments" if message.attachments.empty?
      message.status = :unsent
      message.save!
      flash[:notice] = "Successfully sent message"
      redirect_to root_path
    else
      flash[:notice] = "Successfully #{what == :create ? 'created' : 'updated'} message"
      redirect_to :action => :edit, :id => message.id
    end
  end
  
end
