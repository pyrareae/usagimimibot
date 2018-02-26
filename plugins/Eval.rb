require 'safe_ruby'
require 'cinch'

class Eval
  include Cinch::Plugin

  match /rb (.*)/
  def execute(m, msg)
    m.reply SafeRuby.eval(msg)
  end
end