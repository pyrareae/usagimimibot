require 'cinch'

#require_relative 'join_part'
#require_relative 'search'
#require_relative 'dasmew'
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
      load "plugins/#{file}"
      @list << Kernel.const_get(file.chomp('.rb'))
    end
    @bot.plugins.register_plugins(@list)
  end
  def unload_plugins()
    @bot.plugins.each do |plugin|
      unless plugin == self
        @bot.loggers.debug "[PluginMan] unloading #{plugin}"
        #byebug
        plugin.unregister
        #@bot.plugins.unregister_plugin(plugin)
        #plugin.hooks.clear
        #plugin.matchers.clear
        #plugin.listeners.clear
        #plugin.timers.clear
        #plugin.plugin_name = nil
        #plugin.react_on = :message
        #plugin.help = nil
        #plugin.prefix = nil
        #plugin.suffix = nil
        #plugin.required_options.clear
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
    m.reply "Loaded plugins: #{@list.inspect}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "moon.freenode.net"
    c.channels = ["#meowchattesting"]
    c.nick = 'redmew'
    @adimns = ['lunarkitty7','lunarkitty']
    c.plugins.plugins = [PluginMan]
    #c.plugins.plugins = [JoinPart,Search,DasMew]
  end
end

bot.start
