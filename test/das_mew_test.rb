require_relative 'test_helper'
require_relative '../plugins/das_mew'

class DasMewTest < TestBase
  setup do
    @bot = Cinch::Bot.new {
      self.loggers.clear
    }
    @plugin = DasMew.new @bot
  end

  test 'cinch message mocking' do
    mock = Minitest::Mock.new
    mock.expect :reply, true, ['meow']

    @plugin.echo(mock, 'meow')

    assert mock.verify
  end
end