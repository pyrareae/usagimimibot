require 'cinch'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'


class Search
	include Cinch::Plugin
	match /s (.+)/
	match /a (.+)/, method: :answer

	def answer(m, query)
		res = JSON.parse open("http://api.duckduckgo.com?q=#{CGI.escape query}&format=json&mo_html=1").read
		
		answer = []

    fields = %w{Heading AnswerType}
    footer = %w{AbstractURL}
    body = %w{AbstractText Definition} #only one will be used, the rest are fallbacks
  
    fields.each do |f|
      answer << res[f] unless f.nil? || f.empty?
    end
    b = nil
    body.each do |f|
      b = res[f] unless f.nil? || f.empty?
    end
    answer << b
    footer.each do |f|
      answer << res[f] unless f.nil? || f.empty?
    end
    answer.delete '' #remove empties

		m.reply answer.join(' :: ')
	end

	def execute(m, query)
		num = query[/p(\d)/, 1].to_i
		num -= 1 if num > 0
		query.sub! /p\d/, ''

		scrubber = /(<\/?[^>]*>)|(\n+)|(^ *)|( *$)/
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