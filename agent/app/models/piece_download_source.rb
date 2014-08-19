class PieceDownloadSource < ActiveRecord::Base
  ##########

  FORGIVENESS_TIMEOUT = 600

  ##########
  
  belongs_to  :node
  
  belongs_to  :download,          :class_name => 'PieceDownload', :foreign_key => 'piece_download_id'
  has_one     :download_attempt,  :class_name => 'PieceDownloadAttempt'
  
  ##########

  # this one seems to be correct but I am not satisfied with the randomness it provides - the chance 
  # that a piece will be selected to be attempted is proportional to the number of pieces in an asset -
  # i.e., if asset A has most pieces, we will attempt to download an A's piece more often than other
  # assets' pieces, which is probably OK, but for demo purposes I want to show concurrent downloads
  def self.old_next_to_attempt
    now = Time.now
    find(
      :first,
      :joins => [:node],
      :include => [{ :download => :attempt }],
      :conditions => [
        'piece_downloads.complete <> ? and ' +
        'piece_download_attempts.id is null and ' +
        '(nodes.offline_at is null or nodes.offline_at < ?) and' +
        '(piece_download_sources.failed_at is null or piece_download_sources.failed_at < ?)',
        true,
        now - Node::FORGIVENESS_TIMEOUT,
        now - FORGIVENESS_TIMEOUT
        ],
      :order => 'random()'
    )
  end

  # this implementation is inefficient - but see comment above self#old_next_to_attempt
  def self.inefficient_next_to_attempt
    now = Time.now
    
    # get all sources that are candidates
    sources = find(
      :all,
      :joins => [:node],
      :include => [{ :download => [:attempt, { :piece => :asset }] }],
      :conditions => [
        'piece_downloads.complete <> ? and ' +
        'piece_download_attempts.id is null and ' +
        '(nodes.offline_at is null or nodes.offline_at < ?) and' +
        '(piece_download_sources.failed_at is null or piece_download_sources.failed_at < ?)',
        true,
        now - Node::FORGIVENESS_TIMEOUT,
        now - FORGIVENESS_TIMEOUT
        ]
    ).to_a
    return nil if sources.empty?
    
    # now, sort sources by assets - in the hash below, asset will serve as the key,
    # and list of sources will be values for that key 
    sources_by_asset = {}
    for source in sources
      asset = source.download.piece.asset
      sources_by_asset[asset] ||= []
      sources_by_asset[asset] << source
    end
    
    # select asset randomly
    assets = sources_by_asset.keys
    srand
    assets = assets.sort_by { rand }
    puts ">>> #{assets.collect(&:id).inspect}"
    asset = assets.first
    
    # now, select source for the asset randomly
    asset_sources = sources_by_asset[asset]
    asset_sources = asset_sources.sort_by { rand }
    source = asset_sources.first
    
    source
  end
  
  def self.next_to_attempt
    now = Time.now
    # retrieve an asset download in random order, for which there is at least one node
    # not offline and at least one piece_source without recent failed attempt to download
    asset_download = AssetDownload.find(
      :first,
      :include => { :piece_downloads => [:attempt, { :sources => :node }] },
      :conditions => [
        '(asset_downloads.id is not null) and ' +
        '(piece_downloads.complete <> ?) and ' +
        '(piece_download_attempts.id is null) and ' +
        '(nodes.offline_at is null or nodes.offline_at < ?) and ' +
        '(piece_download_sources.failed_at is null or piece_download_sources.failed_at < ?)',
        true,
        now - Node::FORGIVENESS_TIMEOUT,
        now - FORGIVENESS_TIMEOUT
      ],
      :order => 'random()'
    ) or return nil
    
    # puts ">>>> #{asset_download.asset_id}"
    
    # for the found asset_download, now select source randomly
    next_to_attempt_for_asset_download(asset_download, now)
  end

  ##########
  private

  def self.next_to_attempt_for_asset_download(asset_download, now)
    find(
      :first,
      :joins => [:node],
      :include => [{ :download => [:attempt, :asset_download] }],
      :conditions => [
        '(asset_downloads.id = ?) and ' +
        '(piece_downloads.complete <> ?) and ' +
        '(piece_download_attempts.id is null) and ' +
        '(nodes.offline_at is null or nodes.offline_at < ?) and' +
        '(piece_download_sources.failed_at is null or piece_download_sources.failed_at < ?)',
        asset_download.id,
        true,
        now - Node::FORGIVENESS_TIMEOUT,
        now - FORGIVENESS_TIMEOUT
      ],
      :order => 'random()'
    )
  end

  ##########
end
