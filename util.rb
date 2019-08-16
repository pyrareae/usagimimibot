# frozen_string_literal: true

require 'ostruct'
require 'singleton'

module Usagi
  class Storage < OpenStruct
  end
  class<<self
    def settings
      @settings ||= Storage.new
    end
  end
end
