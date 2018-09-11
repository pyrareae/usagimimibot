require 'cinch'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'net/http'
require_relative '../util'

class Search
	include Cinch::Plugin
	match /s (.+)/, method: :search
	match /What's (.+), precious/i, use_prefix: false, method: :execute
	match /a (.+)/, method: :answer
	match /wiki|w (.+)/, method: :wiki

  #search with ddg instant answer api, very buggy still
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

  #search with web scrape
	def search(m, query)
		num = query[/-(\d)/, 1].to_i
		num -= 1 if num > 0
		query.sub! /-\d/, ''

		scrubber = /(<\/?[^>]*>)|(\n+)|(^ *)|( *$)/
        @bot.loggers.debug query
		page = Nokogiri::HTML(open("https://duckduckgo.com/html?q=#{CGI.escape query}"))
		result = page.css('.web-result')[num]
		title = result.css('.result__title').text.gsub(scrubber, '').gsub(/ +/, ' ')
		desc = result.css('.result__snippet').text.gsub(scrubber, '').gsub(/ +/, ' ')
		url = URI.unescape result.css('a')[0]['href']
		url = url.match(/(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+\#-]*[\w@?^=%&\/~+\#-])?/)

    unless m #internal call
      return {url: url, desc: desc, title: title, result: result, page: page}
		else 
		  m.reply "#{title} :: #{desc} :: #{url}"
		end
	end

  #get wiki page url and display summery
	def wiki(m, query)
    wiki_url = fetch("https://duckduckgo.com/html?q=#{CGI.escape '!wiki '+query}").uri.to_s
    api_url = "https://en.wikipedia.org/api/rest_v1/"
    uri = URI api_url + "page/summary/#{wiki_url[/([^\/]+)\/?$/]}"
    res = Net::HTTP.get uri
    m.reply "#{wiki_url} :: #{JSON.parse(res)["extract"]}"
	end

	private
	  def fetch(uri_str, limit=10)
      raise "too many HTTP redirects" if limit == 0

      response = Net::HTTP.get_response(URI(uri_str))

      case response
      when Net::HTTPSuccess then
        response
      when Net::HTTPRedirection then
        location = response['location']
        fetch location, limit-1
      else
        response.value 
      end
	  end
end