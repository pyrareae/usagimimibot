# frozen_string_literal: true

require 'cinch'
require 'yaml'
require_relative '../util'

class Help
  include Cinch::Plugin
  extend Usagi::Help

  match /help (.*)/

  def execute m, command
    return if /\// =~ command
    m.reply $help_data.values.reduce(&:merge)[command.downcase.chomp] || 'No entry available'
  end

  match /info(?!.)/, method: :default_help
  match /help(?!.)/, method: :default_help

  def default_help m
    m.reply "help: usage: help [plugin]/<command> -- " +
            "Available plugins to query: #{$help_data.keys}"
  end

  match /help (.*?)\/(.*)/, method: :detailed_help

  def detailed_help m, plugin, command
    m.reply $help_data[plugin.downcase.chomp][command.downcase.chomp] || 'No entry available'
  end
end
