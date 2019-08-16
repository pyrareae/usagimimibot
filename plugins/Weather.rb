require 'cinch'
require 'json'
require 'ostruct'
require 'net/http'
require_relative '../util'

class Weather
  include Cinch::Plugin
  def query_weather(q='')
    uri = URI('https://api.openweathermap.org/data/2.5/weather')
    uri.query = URI.encode_www_form({q: q, appid: Usagi.settings.cfg['api_keys']['openweather']})
    p uri
    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body, object_class: OpenStruct)
  end

  def k2f(k)
    ((k - 273.15) * 9/5 + 32).round(2)
  end

  def k2c(k)
    (k - 273.15).round(2)
  end

  match /we (.+)/

  def execute(m, query)
    w = query_weather(query)
    if w.cod == '404'
      m.reply 'bad query'
      return
    end
    ww = w.weather.first
    m.reply("#{w.name}: #{ww.description} | #{k2f w.main.temp}f/#{k2c w.main.temp}c | #{w.clouds&.all}% cloudy | #{w.main.humidity} humidity | wind: #{w.wind&.speed}m/s")
  end 
end
