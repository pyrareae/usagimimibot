# frozen_string_literal: true

require 'cinch'
require_relative '../util.rb'
#########################
# Demon Duck Kitty Game #
#########################

################
# Game Objects #
################

class Entity
  @entity_name = 'Base Entity'

  def self.entity_name
    @entity_name
  end

  def entity_name
    self.class.entity_name
  end

  def announce_text
    entity_name + ' has appeared!'
  end
end

class Demon < Entity

end

class Duck < Entity

end

class Kitty < Entity

end

############
# DATABASE #
############
def create_tables
  Usagi::DB.create_table? :ddk_players do
    primary_key :id
    String :json
    String :nick
    String :server
    String :channel
  end

  Usagi::DB.create_table? :ddk_channels do
    primary_key :id
    String :json
    String :channel
    String :server
    Boolean :enabled
  end
end

class Channel < Sequel::Model(Usagi::DB[:ddk_channels])
  plugin :after_initialize
  attr_accessor :meta
  def after_initialize
    self.json ||= '{}'
    @meta = JSON.parse self.json, symbolize_names: true
    @meta[:entities]&.map! {|e| Marshal.load e }
  end

  def check_spawn(bot)
    spawn(bot)
  end

  def spawn(bot)
    entity = Entity.new
    @meta[:entities] ||= []
    @meta[:entities] << entity

    bot_channel(bot).msg entity.announce_text
  end

  def before_save
    @meta[:entities]&.map! { |e| Marshal.dump e }
    self.json = @meta.to_json
  end

  def bot_channel(bot)
    bot.channel_list.find_ensured channel
  end
end

class Player < Sequel::Model(Usagi::DB[:ddk_players])
  plugin :after_initialize
  attr_accessor :meta
  def after_initialize
    self.json ||= '{}'
    @meta = JSON.parse self.json, symbolize_names: true
    @meta[:entities] ||= {demon: {}, duck: {}, kitty: {}, entity: {count: 0}}
  end

  def catch_on_channel
    entity = channel_model.meta[:entities].sample
    return "There is nothing to catch!" unless entity

    meta[:entities][:entity][:count] ||= 0
    meta[:entities][:entity][:count] += 1
    return "You got a #{entity.entity_name}"
  end

  def before_save
    self.json = @meta.to_json
  end

  def channel_model
    @channel_model ||= Channel.find(channel: channel, server: server)
  end

  def entity_count
    meta[:entities][:entity][:count]
  end
end

################
# Cinch Plugin #
################

class DDK
  include Cinch::Plugin

  def initialize(*)
    super

    @settings = OpenStruct.new({
      tick_interval: 5
    })

    create_tables

    Thread.new do
      loop do
        tick
        sleep @settings.tick_interval
      end
    end

    # @sema = Mutex.new
    # @channels = Usagi::DB[:ddk_channels]
    # @players = Usagi::DB[:ddk_players]
  end
  
  match /.*/
  def execute(m)

  end

  match /ddk ?(.*)/, method: :interface
  def interface(m, param)
    # channel = @channels.where(channel: m.channel.name, server: m.server).first.to_h
    channel = Channel.find_or_create(channel: m.channel.name, server: m.server)
    player = Player.find_or_create(channel: m.channel.name, nick: m.user.nick, server: m.server)
    # unless channel
      # @channels.insert channel: m.channel.name, server: m.server
      # channel = @channels.where(channel: m.channel.name, server: m.server).first.to_h
    # end
    p channel
    case param
    when 'enable'
      channel[:enabled] = true
      m.reply "DDK enabled 👹🦆🙀"
    when 'disable'
      channel[:enabled] = false
      m.reply "DDK disabled 🙀"
    when 'channel dump'
      m.reply channel.inspect
    when 'player dump'
      m.reply player.inspect
    when 'entities'
      m.reply channel.meta[:entities].inspect
    when 'spawn'
      channel.spawn(bot)
      channel.save
    when 'stats'
      m.reply "you have caught #{player.entity_count} debug creatures, yay?"
    else
      m.reply 'Baka! That does not compute!'
    end

    # @channels.where(id: channel[:id]).update(**channel.except(:id))
  end

  match 'catch', method: :catch
  def catch(m)
    player = Player.find_or_create(channel: m.channel.name, nick: m.user.nick, server: m.server)
    m.reply player.catch_on_channel
    plater.save
  end

  def tick
    Channel.where(enabled: true).each do |channel_record|
      bot_channel = bot.channel_list.find_ensured(channel_record[:channel].to_s)
      # channel_record.check_spawn(bot)
    end
  end
end
