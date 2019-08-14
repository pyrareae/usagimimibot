require 'cinch'
require 'yaml'

class Help
  include Cinch::Plugin

  def load_data
    YAML.parse open('../help.yml')
  end

  def execute(m)
    m.reply load_data[m.msg]['desc'] || 'not found'
  end
end