require 'cinch'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'


class Search
	include Cinch::Plugin
	match /!s (.+)/, use_prefix: false
	match /!a (.+)/, use_prefix: false, method: :answer

	def answer(m, query)
		res = JSON.parse open("http://api.duckduckgo.com?q=#{CGI.escape query}&format=json").read
		
		abstract = {desc: res['AbstractText'], url: res['AbstractURL']} if res['AbstractText']

		if abstract
			m.reply "(#{abstract[:desc]} #{if abstract[:desc].length > 0 then '--' end} #{abstract[:url]}"
		else
			m.reply "(no results, try *??)"
		end
	end

	def execute(m, query)
		num = query[/p(\d)/, 1].to_i
		num += 1 if num > 0
		query.sub! /p\d/, ''

		scrubber = /(<\/?[^>]*>)|(\n+)/
        @bot.loggers.debug query
		page = Nokogiri::HTML(open("https://duckduckgo.com/html?q=#{CGI.escape query}"))
		result = page.css('.web-result')[num]
		title = result.css('.result__title').text.gsub(scrubber, '').gsub(/ +/, ' ')
		desc = result.css('.result__snippet').text.gsub(scrubber, '').gsub(/ +/, ' ')
		url = URI.unescape result.css('a')[0]['href']
		url = url.match(/(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+\#-]*[\w@?^=%&\/~+\#-])?/)

		m.reply "#{title} :: #{desc} :: #{url}"
	end
end