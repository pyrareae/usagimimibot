# frozen_string_literal: true

require 'cinch'
require 'faker'

class RandName
  include Cinch::Plugin
  extend Usagi::Help

  info 'randomname', 'Generate random name'
  match /randname/
  def execute(m)
    m.reply(Faker::Name.name)
  end
end
