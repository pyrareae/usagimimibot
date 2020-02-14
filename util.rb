# frozen_string_literal: true

require 'ostruct'
require 'sequel'

module Usagi
  DB = Sequel.connect('sqlite://detabesu.db')
  class<<self
    def settings
      @settings ||= OpenStruct.new
    end
  end
end
