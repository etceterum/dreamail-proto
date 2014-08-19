class HumanController < ApplicationController
  def index
    redirect_to inbox_path
  end
  
  def refresh
    last_in_message_id = params[:last_in_message_id]
    
    unless last_in_message_id.blank?
      @last_in_message = InMessage.received.find(:first, :order => 'in_messages.id desc', :conditions => ['in_messages.id > ?', last_in_message_id])
    end
    
    tracked_in_attachment_ids = JSON.parse(params[:tracked_in_attachment_ids])
    # tracked_in_attachment_ids = [tracked_in_attachment_ids] unless tracked_in_attachment_ids.is_a?(Array)
    tracked_in_attachments = []
    
    # logger.info ">>> #{tracked_in_attachment_ids.inspect}"
    
    for tracked_in_attachment_id in tracked_in_attachment_ids
      tracked_in_attachment = InAttachment.find(tracked_in_attachment_id)
      asset = tracked_in_attachment.asset
      total = asset.pieces.count
      download = asset.download
      progress = download ? total - download.piece_downloads.incomplete.count : total
      data = {
        :id => tracked_in_attachment.id,
        :done => download.nil?,
        :total => total,
        :progress => progress
      }
      tracked_in_attachments << data
    end
    
    output = {
      :counts => {
        :unread   => InMessage.received.unread.count,
        :draft => OutMessage.drafts.count,
        :unsent => OutMessage.unsent.count,
        :sent => OutMessage.sent.count,
        :download => InAttachment.downloading.count
      },
      :last_in_message_id => @last_in_message ? @last_in_message.id : nil,
      :tracked_in_attachments => tracked_in_attachments
    }
    
    respond_to do |format|
      format.json do
        render :json => output.to_json
      end
    end
  end
  
  def trash
  end
  
end
