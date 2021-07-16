ENV['ENVIRONMENT'] = 'test'
require 'minitest/autorun'
require 'minitest/utils'

class TestBase < Minitest::Test
  def initialize(*)
    super
  end
end