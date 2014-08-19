require 'logger'

require 'socketry/client/download'
require 'socketry/asset_download_completer'

module Socketry
  class Downloader
    ##########
    
    def self.logger
      @@logger ||= Logger.new(STDERR)
    end
    
    def self.logger=(l)
      @@logger = l
    end
    
    ##########
    
    attr_writer :logger
    
    def logger
      @logger ||= self.class.logger
    end
    
    def initialize
    end
    
    def download
      asset_downloads = AssetDownload.ordered_by_type.ordered_by_id
    
      for asset_download in asset_downloads
        asset = asset_download.asset
        if asset_download.complete?
          puts "Download complete for asset #{asset.uid}"
          AssetDownloadCompleter.new.complete_asset_download(asset_download)
        else
          piece_mask = BooleanVector.new(0)
        end
      
        # p asset_download.piece_mask.collect {|b| b ? '1' : '0'}
        piece_mask = asset_download.piece_mask
        node_infos = Client.tracker.track_asset(asset.uid, piece_mask)
      
        if node_infos.empty?
          logger.debug "Asset #{asset.uid}: no nodes with the needed pieces are returned by the tracker"
        end
        
        for node_info in node_infos
          # parse node info data for each node
          node_uid = node_info[:uid]
          node_piece_mask = node_info[:pieces]
          node_piece_mask = BooleanVector.new(piece_mask.size, true) if node_piece_mask.empty?
          node_host = node_info[:host]
          node_port = node_info[:port]
          node_public_key_data = node_info[:public_key]
          modulus = OpenSSL::BN.new(node_public_key_data[:n], 2)
          exponent = OpenSSL::BN.new(node_public_key_data[:e].to_s)
          node_public_key = OpenSSL::PKey::RSA.new
          node_public_key.n = modulus
          node_public_key.e = exponent
          
          node_wanted_piece_mask = ~piece_mask & node_piece_mask
          if node_wanted_piece_mask.false?
            logger.error "Node #{node_uid} doesn't have any pieces that we don't have"
            next
          end
          
          # puts "#{node_uid}: #{node_wanted_piece_mask.collect {|b| b ? '1' : '0'}}"
          
          # get piece positions
          piece_positions = (0...node_wanted_piece_mask.size).select { |i| node_wanted_piece_mask[i] }
          
          # get references to piece downloads that correspond to the mask
          piece_downloads = asset_download.piece_downloads.scoped({ :joins => :piece }).scoped({ :conditions => ['pieces.position in (?)', piece_positions] })

          # download pieces - FIXME
          download_client = Client::DownloadClient.new(node_host, node_port, node_uid, node_public_key)
          for piece_download in piece_downloads
            piece = piece_download.piece
            
            logger.info "Downloading #{asset.uid}:#{piece.position} (#{piece.transit_size} bytes)"
            piece_data = download_client.download_piece(piece.uid, piece.transit_checksum)
            piece_download.complete!(piece_data)
          end
          
        end
      
      end
    end
    
    ##########
  end
end
