require 'cinch'
require 'yaml'
require 'byebug'


class PluginMan
  include Cinch::Plugin
  def initialize(*args)
    super
    @list = []
    @admins = ['lunarkitty7']
    load_plugins()
  end

  match 'reload', method: :reload_plugins
  match 'list', method: :list_plugins
  #alias old_reg __register
  #def __register(*args)
  #	@bot.loggers.debug '[Pluginman init]'
  # old_reg(*args)
  #end
  def load_plugins()
    files = Dir.entries('plugins')
    @list = []
    files.grep(/.*\.rb/) do |file|
      @bot.loggers.debug '[PluginMan] loading '+file
      if load "plugins/#{file}"
        @list << Kernel.const_get(file.chomp('.rb'))
      else
        @bots.loggers.debug "[PluginMan] #{file} failed to load" 
      end
    end
    @bot.plugins.register_plugins(@list)
  end
  def unload_plugins()
    @bot.plugins.each do |plugin|
      unless plugin == self
        plugin.unregister
        @bot.loggers.debug "[PluginMan] successfully unloaded #{plugin}"
      end
    end
  end
  def reload_plugins(m)
    #return unless check_user(m.user)
  	unload_plugins()
  	load_plugins()
  	m.reply "Reloaded #{@list.size} plugins."
  end
  def check_user(user)
    user.refresh 
    @admins.include?(user.authname)
  end
  def list_plugins(m)
    #names = []
    #@list.each {|p| names << p.class.name }
    m.reply "[PluginMan] Loaded plugins: #{@list.inspect}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    cfg = YAML.load(open 'conf.yml')
    c.server = cfg['server']
    c.channels = cfg['channels']
    c.nick = cfg['nick']
    @adimns = cfg['admins']
    c.plugins.plugins = [PluginMan]
    #c.plugins.plugins = [JoinPart,Search,DasMew]
  end
end

bot.start
