require 'active_support/concern'

class GlobalID
  module Identification
    extend ActiveSupport::Concern

    def to_global_id(options = {})
      @global_id ||= GlobalID.create(self, options)
    end
    alias to_gid to_global_id

    def to_gid_param(options = {})
      to_global_id(options).to_param
    end
  end
end
