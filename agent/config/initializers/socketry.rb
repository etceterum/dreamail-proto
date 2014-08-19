# p Rails.root
# p File.expand_path(File.join(Rails.root, '..', '..', '..', 'lib'))
$LOAD_PATH << File.expand_path(File.join(Rails.root, 'lib'))

in_instance = File.basename(File.dirname(Rails.root)) == 'instances'
$LOAD_PATH << (in_instance ? File.expand_path(File.join(Rails.root, '..', '..', '..', 'lib')) : File.expand_path(File.join(Rails.root, '..', 'lib')))

require 'socketry/dbhack'
require 'socketry/regex'
require 'socketry/config/node'
require 'socketry/config/user'
require 'socketry/config/ping'
require 'socketry/config/master_client'
require 'socketry/config/tracker_client'

require 'socketry/client/master'
require 'socketry/client/tracker'

require 'socketry/boolean_vector'
require 'socketry/compiler'

require 'socketry/active_record/has_uid'

require 'socketry/attachment_download_initiator'
