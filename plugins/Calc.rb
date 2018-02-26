require 'cinch'

class Calc
  include Cinch::Plugin

  match /calc (.*)/
  def execute(m, msg)
    m.reply parse(tokenize(msg))
  end

  def tokenize(s)
    split_pattern = /( |\+|\-|\*|\/|\)|\()/ 
    s.split(split_pattern)
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

    index.each do |i|
      a, b = tokens[i[1]-1], tokens[i[1]+1]
      val = ops[i[0]][a, b]
      tokens[a+1..b] = nil
      tokens[a] = val 
      tokens.compact!
    end
    tokens
  end
end