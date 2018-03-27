require 'cinch'
require 'byebug'

class Calc
  include Cinch::Plugin

  match /calc (.*)/
  def execute(m, msg)
    m.reply parse(tokenize(msg))
  end

  def tokenize(s)
    split_pattern = /( |\+|\-|\*|\/|\)|\()/ 
    s = s.split(split_pattern)
    s.reject { |e| e.to_s.empty? or e == ' ' }
  end

  def parse(tokens)
    ops = {
        '+' => -> a, b {a+b},
        '-' => -> a, b {a-b},
        '*' => -> a, b {a*b},
        '/' => -> a, b {a/b}
      }
    op_order = %w{* / + -}

    index = []

    #locate positions of operators
    tokens.each_with_index do |token, i|
      if op_order.include? token
        index << [token, i]
      end
    end

    #order by op order and position
    index.sort_by! {|x| [op_order.index(x[0]), x[1]]}
    offset = -> arr, at, amount {arr.map! {|el| el[1] += amount if el[1] >= at }}

    calc = lambda do |t|
      a, b = t[0].to_i, t[2].to_i
      val = ops[t[1]][a, b]
      t[a..b] = nil
      t[a] = val 
      calc[t.compact]
    end
    calc[tokens]
  end
end