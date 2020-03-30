# frozen_string_literal: true

require 'cinch'
require 'zalgo'
require_relative '../util.rb'
require_relative 'guard.rb'

class DasMew
  include Cinch::Plugin
  include Usagi::Guard

  def initialize(*)
    super
    @take_duck = {}
  end

  match /echo (.+)/, method: :echo
  match /<echo (.+)>/, method: :echo, use_prefix: false
  def echo(m, msg)
    m.reply msg.to_s
  end

  match /me (.+)/, method: :action
  def action(m, msg)
    m.action msg
  end

  match /nick (.+)/, method: :nick
  def nick(m, msg)
    admin?(m) do
      m.bot.nick = msg
    end
  end

  match /meow/i, method: :meow, use_prefix: false
  def meow(m)
    meow = Usagi::STORE[:meow]
    Usagi::STORE[:meow] = true if meow.nil?
    return unless Usagi::STORE[:meow]
    m.reply ['Meow!', 'Nya!', 'Mew', ':3', 'Meow~', 'Nya~'].sample
  end

  match /color (.*)/, method: :color
  def color(m, msg)
    m.reply "\x03#{rand(0..15)}" + msg
  end

  match /rainbow (.*)/, method: :rainbow
  def rainbow(m, msg)
    c = [2, 3, 9, 8, 7, 4, 6].cycle
    rand(0..13).times {c.next}
    m.reply msg.split('').reduce('') { |s, i| s + format("\x03%02d%s", c.next, i) }
  end

  match /zalgo (.+)/, method: :zalgo
  def zalgo(m, msg)
    m.reply Zalgo.he_comes msg
  end

  match /([・゜。].*){4}/i, method: :get_duck, use_prefix: false
  def get_duck(m)
    return unless rand < 0.10
    t = Usagi::STORE[:bef_wait] || 60 * 5
    @take_duck[m.channel] = true
    # m.reply "stealing duck in #{t} seconds..."
    Thread.new { sleep t; m.reply ',bef' if @take_duck[m.channel] }
  end

  match /\,bef|\,bang/, method: :cancel_duck, use_prefix: false
  def cancel_duck(m)
    @take_duck[m.channel] = false
  end

  match /store ?(.+)/, method: :store
  def store(m, param)
    # m.reply param
    admin?(m) do
      case param
      when 'dump'
        m.reply Usagi::DB[:usagi_store].all.map{|s| "#{s[:key]} = #{s[:value]}(#{s[:type]})"}.join(', ')
      when /^\[.*?\]\ ?= ?(.+)/
        _, key, val = *param.match(/^\[(.*?)\]\ ?= ?(.+)/)
        Usagi::STORE[key] = val
        m.reply Usagi::STORE[key].inspect
      when /^\[.*\]$/
        value = Usagi::STORE[param[/\[(.*)\]/, 1]]
        m.reply value.nil? ? 'nil' : Usagi::STORE[param[/\[(.*)\]/, 1]]
      end
    end
  end

  match "system", method: :system_info
  def system_info(m)
    vm = `vmstat -s`.lines
    total_ram = vm.find{|l| l["total"]}.lstrip.chomp
    free_ram = vm.find{|l| l["free memory"]}.lstrip.chomp
    m.reply "kernel #{`uname -r`.chomp}, #{RUBY_DESCRIPTION}, #{total_ram}, #{free_ram}"
  end

  match 'test', method: :run_tests
  def run_tests(m)
    admin?(m) or return
    
    m.reply `rake test`.split("\n").reverse.find {|l| l =~ /assertion/}
  end
end
