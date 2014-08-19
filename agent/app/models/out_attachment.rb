class OutAttachment < ActiveRecord::Base
  ##########
  
  named_scope :not_compiled, :conditions => { :asset_id => nil }
  named_scope :not_announced, :joins => :asset, :conditions => 'assets.uid is null'
  named_scope :ordered_by_relative_path, :order => 'relative_path asc'
  
  ##########

  def compiled?
    !asset_id.nil?
  end
  
  def path
    File.join(local_path_prefix, relative_path)
  end

  ##########

  def size
    File.size(path) rescue 0
  end

  ##########

  def announced?
    compiled? && asset.announced?
  end

  ##########
  
  def metainfo
    raise Socketry::InternalError.new unless announced?
    
    data = {
      :path => relative_path,
      :asset => asset.metainfo
    }
  end
  
  ##########
  
  belongs_to  :message, :class_name => 'OutMessage', :foreign_key => 'out_message_id'
  belongs_to  :asset, :dependent => :destroy

  ##########
end
