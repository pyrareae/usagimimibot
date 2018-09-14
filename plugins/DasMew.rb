require 'cinch'
require_relative '../util.rb'

class DasMew
  include Cinch::Plugin

  match /echo (.+)/, method: :echo
  def echo(m, msg)
    m.reply ">> #{msg}"
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
end
