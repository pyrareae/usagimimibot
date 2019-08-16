# frozen_string_literal: true

require 'cinch'
require 'faker'

class RandName
  include Cinch::Plugin

  match /randname/
  def execute(m)
    m.reply(Faker::Name.name)
  end
end
