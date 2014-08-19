class AssetDownload < ActiveRecord::Base
  include Socketry
  
  ##########
  
  DEFAULT_TRACK_INTERVAL  = 5
  EMPTY_PIECE_MASK        = BooleanVector.new(0).freeze
  TYPES                   = [:head, :body, :attachment]
  
  ##########

  belongs_to  :asset
  has_many    :piece_downloads, :dependent => :destroy
  
  ##########

  named_scope :ordered_by_id,   :order => 'asset_downloads.id asc'
  named_scope :ordered_by_type, :order => 'asset_downloads.type_code asc'
  named_scope :not_tracked,     :conditions => { :track_at => nil }

  ##########

  def type
    TYPES[type_code]
  end
  
  def type=(t)
    code = TYPES.index(t)
    raise "Bad type" if code.nil?
    self.type_code = code
  end

  ##########

  def schedule(at = nil)
    self.track_interval ||= DEFAULT_TRACK_INTERVAL
    self.track_at = (at || Time.now) + track_interval
  end
  
  def schedule!(at = nil)
    schedule(at)
    save!
  end

  ##########

  def complete?
    piece_downloads.incomplete.empty?
  end
  
  def piece_mask
    @piece_mask ||= init_piece_mask
  end

  ##########

  # returns a list of two items: 
  # 1. number of pieces already downloaded
  # 2. total number of pieces
  def progress
    total = asset.pieces.count
    downloaded = total - piece_downloads.incomplete.count
    [downloaded, total]
  end

  ##########

  def self.first_to_track
    find(:first, :order => 'track_at asc')
  end
  
  ##########
  private

  def init_piece_mask
    if piece_downloads.incomplete.empty?
      EMPTY_PIECE_MASK
    else
      mask = BooleanVector.new(asset.pieces.count, true)
      for piece_download in piece_downloads.incomplete
        mask[piece_download.piece.position] = false
      end
      mask
    end
  end

  ##########
end
