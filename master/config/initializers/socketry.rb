$LOAD_PATH << File.expand_path(File.join(Rails.root, '..', 'lib'))

require 'socketry/proto'
require 'socketry/encoder'
require 'socketry/regex'
require 'socketry/config/master'
require 'socketry/active_record/has_uid'
require 'socketry/boolean_vector'
