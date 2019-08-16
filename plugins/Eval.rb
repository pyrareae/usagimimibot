# frozen_string_literal: true

require 'safe_ruby'
require 'cinch'
require_relative 'Guard.rb'

class Eval
  include Cinch::Plugin
  include Usagi::Guard

  match /rb (.*)/
  def execute(m, msg)
    admin?(m) do
      m.reply SafeRuby.eval(msg)
    end
  end
end
