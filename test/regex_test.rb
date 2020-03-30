require_relative 'test_helper'
require_relative '../plugins/regex'

class RegexTest < TestBase
  def initialize(*)
    super
    Usagi::DB.create_table? :messages do
      primary_key :id
      String :message
      String :channel
      String :server
      String :nick
      DateTime :time
    end 
    Usagi::DB[:messages] << {
        message: 'meow',
        time: Time.now,
        channel: '#nyan',
        server: 'nyannet',
        nick: 'mew'
      }
  end
  setup do
    @bot = Cinch::Bot.new {
      self.loggers.clear
    }
    @plugin = Regex.new @bot
    @mock = Minitest::Mock.new
    @mock.expect :channel, OpenStruct.new(name: '#nyan')
    @mock.expect :server, 'nyannet'
  end

  test 'standard regex command' do
    @mock.expect :reply, nil, ['nya']
    2.times {@mock.expect :message, 's/meow/nya/'}
    @plugin.execute(@mock)
    @mock.verify
  end

  test 'regex command withoug trailing slash' do
    @mock.expect :reply, nil, ['nya']
    2.times {@mock.expect :message, 's/meow/nya'}
    @plugin.execute(@mock)
    @mock.verify
  end

  test 'find message' do
    @mock.expect :reply, nil, ['meow']
    3.times {@mock.expect :message, 's/meow'}
    @plugin.execute(@mock)
    @mock.verify
  end
end