class InAttachment < ActiveRecord::Base
  ##########
  
  belongs_to  :message, :class_name => 'InMessage', :foreign_key => 'in_message_id'
  belongs_to  :asset

  ##########
  
  named_scope :downloading, :include => { :asset => :download }, :conditions => 'asset_downloads.id is not null'
  
  ##########

  def here?
    asset && asset.here?
  end
  
  def downloading?
    asset && asset.downloading?
  end

  ##########

  # see AssetDownload#progress
  def download_progress
    return [0, 0] unless asset
    return [asset.pieces.count, asset.pieces.count] unless asset.download
    asset.download.progress
  end
  
  def download_percentage
    progress = download_progress
    return 0 if progress.last == 0
    percentage = progress.first*100/progress.last
    # logger.error ">>> #{progress.inspect} -> #{percentage}"
    percentage
  end

  ##########
end
