require 'cinch'
require_relative '../util.rb'

class DasMew
  include Cinch::Plugin

  def initialize(*args)
    super
    @take_duck = {}
  end

  match /echo (.+)/, method: :echo
  def echo(m, msg)
    m.reply "#{msg}"
  end

  match /me (.+)/, method: :action
  def action (m, msg)
    m.action msg
  end

  match /meow/i, method: :meow, use_prefix: false
  def meow(m)
    m.reply ["Meow!", "Nya!", "Mew", ":3", "Meow~", "Nya~"].sample
  end

  match /color (.*)/, method: :color
  def color(m, msg)
    m.reply "\x0303"+msg
  end

  match /rainbow (.*)/, method: :rainbow
  def rainbow(m, msg)
    c = (0..15).cycle
    m.reply msg.split('').reduce('') { |s, i| s+"\x03%02d%s" % [c.next, i] }
  end

  #match /([・゜。].*){4}/i, method: :get_duck, use_prefix: false
  def get_duck(m)
    t = 60*20
    @take_duck[m.channel] = true
    m.reply "stealing duck in #{t} seconds..."
    Thread.new {sleep t; m.reply ',bef' if @take_duck[m.channel]}
  end

  #match /\,bef/, method: :cancel_duck, use_prefix: false
  def cancel_duck(m)
    @take_duck[m.channel] = false
  end
end
