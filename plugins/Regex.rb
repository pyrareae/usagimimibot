# frozen_string_literal: true

require 'cinch'
require_relative '../util.rb'

class Regex
  include Cinch::Plugin

  def initialize(*arg)
    @log = {}
    super
  end

  match /.*/, use_prefix: false
  def execute(m)
    @log[m.channel] ||= [] # init if none
    regex_str = m.message[%r{/(.*)/}, 1]
    replace_str = m.message[%r{/.*/(.*)}, 1]
    if regex_str && m.message[/^!.*/]
      @log[m.channel].each do |msg|
        result = msg[:msg][/#{regex_str}/]
        next unless result

        if replace_str && !replace_str.empty?
          m.reply "(#{msg[:nick]}) #{msg[:msg].gsub /#{regex_str}/, replace_str}"
        else
          m.reply "(#{msg[:nick]}) #{msg[:msg]}"
          end
        return
      end
      m.reply "No matches for /#{regex_str}/"
    else
      @log[m.channel] << { msg: m.message, nick: m.user } # log it
      @log[m.channel].shift if @log[m.channel].size > 24
    end
  end
  match /regex_channel_buffer/, method: :return_log
  def return_log(m)
    m.reply @log[m.channel].map { |l| "(#{l[:nick]}) #{l[:msg]}" }.join(', ')
  end
end
