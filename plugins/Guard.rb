# frozen_string_literal: true

require 'cinch'

module Usagi
  module Guard
    def self.init(bot)
      cfg = Usagi.settings.cfg
      cfg['groups'].each_pair do |name, _members|
        bot.loggers.debug 'creating helper for %s' % name
        send(:define_method, "#{name}?") do |m, &block|
          bot.loggers.warn "Failed auth attempt #{m.user}"
          if cfg['groups'][name].include?(m.user.nick) || cfg['groups']['admin'].include?(m.user.nick)
            block.call
          else
            m.reply 'You are not in group %s' % name
          end
        end
      end
    end
  end
end

class Guard
  include Cinch::Plugin

  def initialize(*args)
    super
    Usagi::Guard.init @bot
  end
end
