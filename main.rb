require 'cinch'
require 'yaml'
require 'byebug'
require_relative 'util.rb'

class PluginMan
  include Cinch::Plugin
  def initialize(*args)
    super
    @list = []
    @cfg = YAML.load(open 'conf.yml')
    Usagi.settings.cfg = @cfg
    @adimns = @cfg['admins']
    load_plugins()
  end

  match /reload (.*)/, method: :reload_plugins
  match 'list', method: :list_plugins
  #alias old_reg __register
  #def __register(*args)
  #	@bot.loggers.debug '[Pluginman init]'
  # old_reg(*args)
  #end
  def load_plugins()
    files = Dir.entries('plugins')
    @list = []
    @status = []
    files.grep(/.*\.rb/) do |file|
      @bot.loggers.debug '[PluginMan] loading '+file
      @status << {name: file.chomp('.rb')}
      begin
        if @cfg['blacklist'].include? file.chomp('.rb')
          @bot.loggers.debug "[PluginMan] #{file} skipping" 
          @status.last[:status] = :disabled
        elsif load "plugins/#{file}"
          plugin = Kernel.const_get(file.chomp('.rb')) 
  	  #plugin.db = @db if defined?(plugin.db=1)
  	      @list << plugin
  	      @status.last[:status] = :ok
        else
          @bots.loggers.debug "[PluginMan] #{file} failed to load" 
          @status.last[:status] = :fail
        end
      rescue => e
        @status.last[:status] = :error
        @bot.loggers.debug "Exception loading plugin: #{ file }"
        @bot.loggers.debug "Exception class: #{ e.class.name }"
        @bot.loggers.debug "Exception message: #{ e.message }"
        @bot.loggers.debug "Exception backtrace: #{ e.backtrace }"
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
  
  def status_message
    c = {ok: :green, error: :red, fail: :red, disabled: :yellow}
    @status.reduce([]){ |m, i| m << "[#{Format(c[i[:status]], i[:name])}]" }.join(', ')
  end
  
  def reload_plugins(m, msg)
    @cfg = YAML.load(open 'conf.yml')
    Usagi.settings.cfg = @cfg
    #return unless check_user(m.user)
  	unload_plugins()
  	load_plugins()
  	#m.reply "Reloaded #{@list.size} plugins."
  	failed = @status.count {|i| i[:status]==:failed || i[:status]==:error}
  	disabled = @status.count {|i| i[:status]==:disabled}
  	response = "Reloaded: #{@status.count {|i| i[:status]==:ok}}"
  	response << ", failed: %d" % failed if failed > 0
  	response << ", disabled: %d" % disabled if disabled > 0
  	response << ' ' + status_message if msg[/-s/]
  	m.reply response
  end
  
  def check_user(user)
    user.refresh 
    @admins.include?(user.authname)
  end
  
  def list_plugins(m)
    #names = []
    #@list.each {|p| names << p.class.name }
    m.reply status_message
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    cfg = YAML.load(open 'conf.yml')
    c.server = cfg['server']
    c.channels = cfg['channels']
    c.nick = cfg['nick']
    c.plugins.plugins = [PluginMan]
    c.plugins.prefix = /^#{cfg['prefix']}/ || /^!/
    #c.plugins.plugins = [JoinPart,Search,DasMew]
  end
end

bot.start
