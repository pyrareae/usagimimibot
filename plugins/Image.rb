require "cinch"
require "mini_magick"
require "drawille"

module Usagi::Image
  def draw(image_url, height: 4, width: 40, threshhold: 150)
    canvas = Drawille::Canvas.new
    image = MiniMagick::Image.open image_url
    image.combine_options do |o|
      o.resize "#{width*2}x#{height*4}"
      o.equalize
      o << "-background" << "white" << "-alpha" << "remove"
    end
    #image.resize '%d'% [height*4]
    image.get_pixels.each_with_index do |row, y| 
      row.each_with_index do |pixel, x| 
        canvas.set(x, y) if pixel[1..3].reduce{|a,i|i+a}/3 > 128
      end
    end
    #canvas.frame.gsub('⠀', ' ')#sub empty braille with space to make it look better on weird terminals
    canvas.frame
  end
  module_function :draw
end

class Image
  include Cinch::Plugin
  match /draw_image (.*)/
  def execute(m, msg)
    m.reply Usagi::Image.draw msg, height: 8
  end
end