# frozen_string_literal: true

require 'cinch'

class Regex
  include Cinch::Plugin
  extend Usagi::Help

  def initialize(*arg)
    @log = Usagi::DB[:messages]
    Usagi::STORE['re_search_limit'] ||= 250
    #Usagi::STORE[:real_regex] = false if Usagi::STORE[:real_regex].nil?
    super
  end

  info 'regex', 'Search backlog with regexp. !/<regex>[/replacement text]'
  match %r{^!/.*}, use_prefix: false
  def execute(m)
    r = m.message.strip.match(/!\/([^\\\/]*?)\/([^\\\/]*)\/?/)
    r ||= m.message.strip.match(/!\/(.*[^\\\/])\/?/)
    matcher = r[1]
    replace_str = r[2]
    count = 0
    use_re = Usagi::STORE[:real_regex]
    #sqlite doesn't do fancy regex  
    msg = @log.where(channel: m.channel.name, server: m.server).exclude(nick: bot.nick).reverse(:time).limit(Usagi::STORE['re_search_limit']).find do |log| 
      count+=1
      log[:message][%r{#{matcher}}] &&
      log[:message] != m.message &&
      !log[:message][/^s\/.*/]
    end

    if !!msg
      timestamp = count > 20 ? "(#{msg[:nick]} #{msg[:time].gmtime.strftime('%m/%d/%y %H:%M:%S')}) " : ''
      if replace_str
        m.reply "#{timestamp}#{msg[:message].gsub /#{matcher}/, replace_str}"
      else
        m.reply "#{timestamp}#{msg[:message]}"
      end
    else
      m.reply "No matches for #{matcher}"
    end
  end
end
