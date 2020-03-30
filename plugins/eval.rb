# frozen_string_literal: true

require 'safe_ruby'
require 'cinch'
require_relative 'guard.rb'

class Eval
  include Cinch::Plugin
  include Usagi::Guard

  match /rb (.*)/
  def execute(m, msg)
    admin?(m) do
      begin
        m.reply SafeRuby.eval(msg)
      rescue => e
        m.reply e.message
      end
    end
  end
end
