class FilesystemController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  FILESYSTEM_ROOT = File.expand_path(File.join('..', '..', '..', 'data', 'test'), Rails.root).to_s.freeze
  
  def ls
    @root = params[:dir]
    @path = File.expand_path(@root, FILESYSTEM_ROOT)
    return unless FILESYSTEM_ROOT == @path.slice(0, FILESYSTEM_ROOT.length)
    @directories, @files = Dir.glob(File.join(@path, '*')).partition { |file| File.directory? file }
    @directories.collect! { |file| file.slice(1 + FILESYSTEM_ROOT.length, file.length) }
    @files.collect! { |file| file.slice(1 + FILESYSTEM_ROOT.length, file.length) }
    render :partial => 'ls'
  end
  
  # returns JSON of a tree under the given path
  def tree
    @root = params[:root]
    @path = File.expand_path(@root, FILESYSTEM_ROOT)
    return unless FILESYSTEM_ROOT == @path.slice(0, FILESYSTEM_ROOT.length)
    
    dir_mode = File.directory? @path
    if dir_mode
      @directories, @files = Dir.glob(File.join(@path, '**', '**')).partition { |file| File.directory? file }
    else
      @directories, @files = [], [@path]
    end
    
    # @files.collect! { |file| file.slice(1 + FILESYSTEM_ROOT.length, file.length) }
    output = []
    for file in @files
      rel_path = dir_mode ? file.slice(1 + FILESYSTEM_ROOT.length, file.length) : File.basename(file)
      abs_prefix = file.slice(0, file.length - rel_path.length - 1)
      output << { 
        :path => file,
        :pref => abs_prefix,
        :suff => rel_path,
        :size => File.size(file)
      }
    end
    
    respond_to do |format|
      format.json { render :json => output.to_json }
    end
  end
  
end
