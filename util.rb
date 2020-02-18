# frozen_string_literal: true

require 'ostruct'
require 'sequel'
require 'singleton'

module Usagi
  DB = Sequel.connect('sqlite://detabesu.db')
  class<<self
    def settings
      @settings ||= OpenStruct.new
    end
  end

  class Store
    ALLOWED_TYPES = %w[String Float Integer].freeze
    include Singleton
    def initialize
      DB.create_table? :usagi_store do
        primary_key :id
        String :key
        String :type
        index :key, unique: true
        String :value
      end
      @sema = Mutex.new
    end

    def [](key)
      key = key.to_s
      entry = DB[:usagi_store].where(key: key).first
      return unless entry
      throw 'Invalid stored type' unless ALLOWED_TYPES.include? entry[:type]

      val = entry[:value]
      method(entry[:type]).call val
    end

    def []=(key, value)
      key = key.to_s
      type = 'String'
      type = 'Float' if value.is_a?(Float) || (value.is_a?(String) && value&.is_float?)
      type = 'Integer' if value.is_a?(Integer)  || (value.is_a?(String) && value&.is_i?)
      @sema.synchronize do
        if DB[:usagi_store].where(key: key).first
          DB[:usagi_store].where(key: key).update(value: value, type: type)
        else
          DB[:usagi_store].insert(key: key, value: value.to_s, type: type)
        end
      end
    end
  end
  STORE = Store.instance
end

class String
  def from_json
    JSON.parse(self, object_class: OpenStruct)
  end

  def is_i?
    /\A[-+]?\d+\z/ === self
  end

  def is_float?
  !!Float(self) rescue false
end
end