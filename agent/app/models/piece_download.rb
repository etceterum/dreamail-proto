class PieceDownload < ActiveRecord::Base
  ##########

  named_scope :complete, :conditions => { :complete => true }
  named_scope :incomplete, :conditions => { :complete => false }
  named_scope :ordered_by_position, :joins => :piece, :order => 'pieces.position asc'
  
  named_scope :not_being_attempted, :include => :attempt, :conditions => 'piece_download_attempts.id is null'

  ##########
  
  belongs_to  :asset_download
  belongs_to  :piece
  
  has_many    :sources, :class_name => 'PieceDownloadSource', :dependent => :destroy
  has_one     :attempt, :class_name => 'PieceDownloadAttempt', :dependent => :destroy

  ##########

  def complete!(data)
    piece.download_complete!(data)
    self.complete = true
    save!
  end

  ##########
end
