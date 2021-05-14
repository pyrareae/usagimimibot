require 'cinch'
require_relative '../util.rb'

class Divination
  include Cinch::Plugin
  include Usagi::Guard
  extend Usagi::Sugar

  command /tarot/ do |m|
    card = cards.sample
    m.reply "#{card}#{rand>0.5 ? ' [reversed]' : ''} astrology.com/tarot/card-meanings/#{card.downcase.gsub(/\d/, NUMS.map.with_index{[_2.to_s, _1]}.to_h).gsub(/\s+/, '-')}"
  end

  def cards
    cards = ['the fool','the magician','the high priestess','the empress','the emperor','the hierophant','the lovers','the chariot','justice','the hermit','wheel of fortune','strength','the hanged man','death','temperance','the devil','the tower','the star','the moon','the sun','judgement','the world',
      ['wands','pentacles','cups','swords'].map do |suit|
        [
          (2..10).map {|n|"#{n} of #{suit}"},
          ['ace','page','knight','queen','king'].map{|type| "#{type} of #{suit}"}
        ]
      end
    ].flatten.map{|card| card.split(" ").map{|word| ['of'].include?(word) ? word : word.capitalize}.join(" ")}
  end

  NUMS = %w[ zero one two three four five six seven eight nine ten ]
end