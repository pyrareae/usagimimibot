# frozen_string_literal: true

require 'cinch'
require_relative '../util.rb'

class Regex
  include Cinch::Plugin

  def initialize(*arg)
    @log = Usagi::DB[:messages]
    Usagi::STORE['re_search_limit'] ||= 250
    super
  end

 match %r{^s/.*}, use_prefix: false
  def execute(m)
    regex_str = m.message[%r{/(.*?)/}, 1]
    find_str = m.message[%r{/(.*)$}, 1]
    matcher = regex_str || find_str
    replace_str = m.message[%r{/.*?/(.*)}, 1]

    # _, regex_str, replace_str = m.message[%r{^s/(.*?)/(.*?)(/|$)}]
    # find_str = m.message[%r{^s/(.*)$}, 1]
    # matcher = regex_str || find_str
    # replace_str = m.message[%r{/.*/(.*)?/}, 1]
    count = 0
    #sqlite doesn't do fancy regex  
    msg = @log.where(channel: m.channel.name, server: m.server).exclude(nick: bot.nick).reverse(:time).limit(Usagi::STORE['re_search_limit']).find do |log| 
      count+=1
      log[:message][%r{#{matcher}}] &&
      log[:message] != m.message &&
      !log[:message][/^s\/.*/]
    end

    if !!msg
      timestamp = count > 20 ? "(#{msg[:nick]} #{msg[:time].gmtime.strftime('%m/%d/%y %H:%M:%S')}) " : ''
      if replace_str && !replace_str.empty?
        m.reply "#{timestamp}#{msg[:message].gsub /#{regex_str}/, replace_str}"
      else
        m.reply "#{timestamp}#{msg[:message]}"
      end
    else
      m.reply "No matches for #{matcher}"
    end
  end
end
