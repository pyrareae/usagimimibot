require 'cinch'
require 'yaml'
require 'byebug'

class PluginMan
  include Cinch::Plugin
  def initialize(*args)
    super
    @list = []
    @cfg = YAML.load(open 'conf.yml')
    @adimns = @cfg['admins']
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
      if @cfg['blacklist'].include? file.chomp('.rb')
        @bots.loggers.debug "[PluginMan] #{file} skipping" 
      elsif load "plugins/#{file}"
        plugin = Kernel.const_get(file.chomp('.rb')) 
    #plugin.db = @db if defined?(plugin.db=1)
    #inject config
    class << plugin
            @@conf = @cfg
    end
    @list << plugin
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
        @bot.loggers.debug "[Pluginman] successfully unloaded #{plugin}"
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
    c.plugins.plugins = [PluginMan]
    #c.plugins.plugins = [JoinPart,Search,DasMew]
  end
end

bot.start
