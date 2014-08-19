require 'active_record'
require 'socketry/uid'

module Socketry
  module ActiveRecord
    module HasUID
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      def ensure_uid
        self.uid ||= self.class.create_uid
      end

      module ClassMethods

        def has_uid
          validates_uniqueness_of :uid
          validates_length_of :uid, :is => 32
          before_validation_on_create :ensure_uid
          @@has_uid = true
        end

        def has_uid?
          @@has_uid
        end

        def create_uid
          uid = nil
          loop do
            uid = Socketry::UID.random.hex
            break unless self.find_by_uid(uid)
          end
          uid
        end

      end
    end
  end
end

class ActiveRecord::Base
  include Socketry::ActiveRecord::HasUID
end
