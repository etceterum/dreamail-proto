class InAttachmentsController < ApplicationController

  # open an attachment from local filesystem
  def open
    @attachment = InAttachment.find(params[:id])
    send_file(@attachment.asset.path, :filename => File.basename(@attachment.relative_path))
  end
  
  # initiate download of an attachment not already downloaded/being downloaded
  def download
    @attachment = InAttachment.find(params[:id])
    Socketry.attachment_download_initiator.initiate_attachment_download(@attachment)
    render :partial => 'downloading', :locals => { :attachment => @attachment }
  end
  
  # change download status to ready
  def ready
    @attachment = InAttachment.find(params[:id])
    render :partial => 'ready', :locals => { :attachment => @attachment }
  end
  
  def downloads
    # @attachments = InAttachment.downloading
  end
  
  def downloads_list
    @attachments = InAttachment.downloading
    render :partial => 'downloads', :locals => { :attachments => @attachments }
  end
  
end
