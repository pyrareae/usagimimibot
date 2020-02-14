# frozen_string_literal: true

require 'cinch'
require_relative '../util.rb'

class Regex
  LIMIT = 250
  include Cinch::Plugin

  def initialize(*arg)
    @log = Usagi::DB[:messages]
    super
  end

  match %r{s/.*}, use_prefix: false
  def execute(m)
    # regex_str = m.message[%r{/(.*)/}, 1]
    # replace_str = m.message[%r{/.*/(.*)}, 1]
    # if regex_str && m.message[/^!.*/]
    #   @log.where(channel: m.channel.name).order(:time).limit().each do |msg|
    #     result = msg[:msg][/#{regex_str}/]
    #     next unless result

    #     if replace_str && !replace_str.empty?
    #       m.reply "(#{msg[:nick]}) #{msg[:msg].gsub /#{regex_str}/, replace_str}"
    #     else
    #       m.reply "(#{msg[:nick]}) #{msg[:msg]}"
    #       end
    #     return
    #   end
    #   m.reply "No matches for /#{regex_str}/"
    # end
    regex_str = m.message[%r{/(.*)/}, 1]
    find_str = m.message[%r{/(.*)$}, 1]
    replace_str = m.message[%r{/.*/(.*)}, 1]
    #sqlite doesn't do fancy regex
    msg = @log.where(channel: m.channel.name, server: m.server).reverse(:time).limit(LIMIT).find {|log| log[:message][%r{#{regex_str || find_str}}] }

    if !!msg
      timestamp = msg[:time].gmtime.strftime('%m/%d/%y %H:%M:%S')
      if replace_str && !replace_str.empty?
        m.reply "(#{msg[:nick]}|#{timestamp}) #{msg[:message].gsub /#{regex_str}/, replace_str}"
      else
        m.reply "(#{msg[:nick]}|#{timestamp}) #{msg[:message]}"
      end
    else
      m.reply "No matches for /#{regex_str}/"
    end
  end
end
