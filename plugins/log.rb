# frozen_string_literal: true

require 'cinch'
require_relative '../util.rb'

class Log
  include Cinch::Plugin
  def initialize(*)
    super

    Usagi::DB.create_table? :messages do
      primary_key :id
      String :message
      String :channel
      String :server
      String :nick
      DateTime :time
    end

    @messages = Usagi::DB[:messages]
    @sema = Mutex.new
    Usagi::STORE['log_max'] ||= 10_000
  end

  match /.*/, use_prefix: false
  def execute(m)
    @sema.synchronize do
      @messages.insert(
        message: m.message,
        time: Time.now,
        channel: m&.channel&.name,
        server: m.server,
        nick: m.user.nick
      )
    end
    if @messages.count > Usagi::STORE['log_max']
      trim Usagi::STORE[:log_max] - 100 # keep from executing every message
    end
  end

  match /log (.+)/, method: :return_log
  def return_log(m, param)
    lines = param.to_i || 20
    msg = @messages.where(channel: m.channel.name).reverse(:time).limit(lines).all.map do |m|
      "[#{m[:time].gmtime.strftime('%m/%d/%y %H:%M:%S')}|#{m[:nick]}|#{m[:message]}]"
      # m.inspect
    end.join(', ')
    m.reply msg
  end

  match 'loglen', method: :log_len
  def log_len m
    m.reply "#{@messages.count} lines across all channels, #{@messages.where(channel: m.channel.name).count} in current channel"
  end

  match /seen (.+)/, method: :seen
  def seen(m, user)
    msg = @messages.reverse(:time).where(channel: m.channel.name, nick: user).limit(1).first
    m.reply "#{user} seen @ #{msg[:time].gmtime.strftime('%m/%d/%y %H:%M:%S')} saying \"#{msg[:message]}\"" if msg
  end

  def trim(n=Usagi::STORE['log_max'])
    Usagi::DB.run %Q{
      DELETE FROM `messages`
      WHERE id NOT IN (
        SELECT id
        FROM (
          SELECT id
          FROM `messages`
          ORDER BY time DESC
          LIMIT #{n} -- keep this many records
        ) foo
      )
    }
  end
end 
