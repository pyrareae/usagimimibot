require 'cinch'
require 'json'
require 'ostruct'
require 'net/http'

class Weather
  include Cinch::Plugin
  extend Usagi::Help
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

  def icon(name)
    @icons ||= JSON.parse(File.read('data/ow_icons.json'))
    @icons.fetch(name)
  end

  info 'we', 'Fetch weather. we <query>'
  match /we (.+)/

  def execute(m, query)
    w = query_weather(query)
    if w.cod == '404'
      m.reply 'bad query'
      return
    end
    ww = w.weather.first
    m.reply([
      icon(ww.icon),
      "#{w.name}: #{ww.description}",
      "current: #{k2f w.main.temp}f/#{k2c w.main.temp}c",
      "feels like: #{k2f w.main.feels_like}f/#{k2c w.main.feels_like}c",
      "min~max: #{k2f w.main.temp_min}f/#{k2c w.main.temp_min}c ~ #{k2f w.main.temp_max}f/#{k2c w.main.temp_max}c",
      w.clouds&.all && "#{w.clouds.all}% cloudy", 
      "#{w.main.humidity}% humidity",
      w.wind&.speed && "wind: #{w.wind.speed}m/s"
    ].compact.join(' | '))
  end 
end
