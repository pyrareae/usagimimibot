require 'cinch'
require_relative '../util.rb'

class DasMew
  include Cinch::Plugin
  include Util

  match /echo (.+)/, method: :echo
  def echo(m, msg)
    m.reply ">> #{msg}"
  end

  match /meow/i, method: :meow, use_prefix: false
  def meow(m)
    m.reply ["Meow!", "Nya!", "Mew", ":3", "Meow~", "Nya~"].sample
  end

  match /count/, method: :count
  def count(m)
  end
end
