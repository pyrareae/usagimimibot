# frozen_string_literal: true

require 'cinch'
require_relative '../util'

module Usagi::Calc
  def tokenize(s)
    split_pattern = %r{( |\+|\-|\*|/|\)|\()}
    s = s.split(split_pattern)
    s.reject { |e| e.to_s.empty? || (e == ' ') }
  end
  module_function :tokenize

  class Op
    attr_reader :sym
    def initialize(symbol, &block)
      @sym = symbol
      @action = block
    end

    def exec(a, b)
      @action[a.to_f, b.to_f]
    end
  end

  class Group
    def initialize(op, a, b)
      @op = op
      @a = a
      @b = b
    end

    def exec
      a = @a.class == Group ? @a.exec : @a
      b = @b.class == Group ? @b.exec : @b
      @op.exec a, b
    end
  end

  def parse(tokens)
    ops = [
      Op.new('*') { |a, b| a * b },
      Op.new('/') { |a, b| a / b },
      Op.new('+') { |a, b| a + b },
      Op.new('-') { |a, b| a - b }
    ]

    ast = tokens
    head = 0
    ops.each do |op|
      loop do
        dirty = false
        tokens.each_with_index do |t, i|
          next unless t == op.sym

          group = Group.new(op, ast[i - 1], ast[i + 1])
          ast[i - 1..i + 1] = []
          ast.insert i - 1, group
          dirty = true
          break
        end
        break unless dirty
      end
    end
    ast[0]
  end
  module_function :parse

  def calc(str)
    parse(tokenize(str)).exec
  end
  module_function :calc
end

class Calc
  include Cinch::Plugin
  include Usagi::Calc
  extend Usagi::Help

  info 'calc', 'Simple calculator. Usage: calc <expression>'
  match /calc (.*)/
  def execute(m, msg)
    m.reply '%g' % calc(msg)
  end
end
