class PieceDownloadAttempt < ActiveRecord::Base
  ##########
  
  belongs_to  :download, :class_name => 'PieceDownload', :foreign_key => 'piece_download_id'
  has_one     :piece, :through => :download
  
  belongs_to  :source, :class_name => 'PieceDownloadSource', :foreign_key => 'piece_download_source_id'
  has_one     :node, :through => :source
  
  ##########
end
