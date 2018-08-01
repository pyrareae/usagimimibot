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
    @log[m.channel] ||= [] #init if none
    regex_str = m.message[/\/(.*)\//, 1]
    replace_str = m.message[/>>(.*)/, 1]
    if regex_str and m.message[/^!.*/]
      @log[m.channel].each do |msg|
        result = msg[/#{regex_str}/]
        if result
          unless replace_str
            m.reply result
          else
            m.reply msg.gsub /#{regex_str}/, replace_str
          end
          return
        end
      end
      m.reply "No matches for /#{regex_str}/"
    else
      @log[m.channel] << m.message #log it
      @log[m.channel] = @log[m.channel][0,25]#limit it
    end
  end
  match /return_log/, method: :return_log
  def return_log(m)
    m.reply @log[m.channel].join(' /\/ ')
  end
end