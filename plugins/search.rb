# frozen_string_literal: true

require 'cinch'
require 'open_uri_redirections'
# require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'net/http'
require 'ostruct'
require_relative 'image'

module Usagi::Search
  def search(query)
    num = query[/-(\d)/, 1].to_i
    num -= 1 if num > 0
    query.sub! /-\d/, ''

    html_element_re = %r{(</?[^>]*>)|(\n+)|(^ *)|( *$)}
    page = Nokogiri::HTML(open("https://duckduckgo.com/html?q=#{CGI.escape query}"))
    result = page.css('.web-result')[num]
    title = result.css('.result__title').text.gsub(html_element_re, '').gsub(/ +/, ' ')
    desc = result.css('.result__snippet').text.gsub(html_element_re, '').gsub(/ +/, ' ')
    url = URI.unescape result.css('a')[0]['href']
    url = url.match(%r{(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+\#-]*[\w@?^=%&/~+\#-])?})

    OpenStruct.new url: url, desc: desc, title: title, result: result, page: page
  end
  module_function :search

  def image(query, result_num: nil)
    num = query[/-p(\d+)/, 1].to_i || result_num
    num -= 1 if num > 0
    query.sub! /-p(\d+)/, ''

    res = nil
    # domain = Usagi.settings.cfg['search']['searx_domains'][0]
    Usagi.settings.cfg['search']['searx_domains'].each do |domain|
      begin
         # puts "[Image Search] trying #{domain}"
         uri = URI domain
         uri.query = URI.encode_www_form format: 'json', q: '!images ' + query, safesearch: '1', engines: 'google'
         res = Net::HTTP.get uri
         break unless res[/Rate limit/]
      rescue StandardError => e
        p e.message
       end
    end
    return false if res[/Rate limit/]

    res_json = JSON.parse res, object_class: OpenStruct
    # puts "[Image Search] using #{res_json.results[num]}"
    res_json.results[num]
  end
  module_function :image
end

class Search
  include Cinch::Plugin
  extend Usagi::Help
  info 's', 'Search for query. s <query>'
  match /s (.+)/, method: :search
  match /What's (.+), precious/i, use_prefix: false, method: :execute
  # match /a (.+)/, method: :answer
  info 'wiki', 'Wiki search'
  match /wiki (.+)/, method: :wiki
  info 'i', 'Image search'
  match /i (.*)/, method: :image_search

  # search with ddg instant answer api, very buggy still
  def answer(m, query)
    res = JSON.parse open("http://api.duckduckgo.com?q=#{CGI.escape query}&format=json&mo_html=1").read

    answer = []

    fields = %w[Heading AnswerType]
    footer = %w[AbstractURL]
    body = %w[AbstractText Definition] # only one will be used, the rest are fallbacks

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
    answer.delete '' # remove empties

    m.reply answer.join(' :: ')
  end

  # search DuckDuckGo with web scrape
  def search(m, query)
    r = Usagi::Search.search(query)
    max_chars = 300
    available_chars = max_chars - r.title.length - r.url.length - 6
    m.reply "#{r.title} | #{r.desc.length < available_chars ? r.desc : "#{r.desc[0...available_chars-1]}…"} | #{r.url}".gsub('...', '…')
  end

  def image_search(m, query)
    reg = / -h(\d+)/
    should_print = query[reg]
    print_h = query[reg, 1] || 4
    print_h = [print_h.to_i, 15].min
    query.sub!(reg, '')
    r = Usagi::Search.image(query)
    unless r
      m.reply 'too many queries, try again later'
      return
    end
    msg = [r.title, r.img_src]
    begin
       msg << "\n" + Usagi::Image.draw(r.img_src.gsub(%r{^//}, 'http://'), height: print_h) # if should_print
    rescue StandardError => e
      m.reply e.message
     end
    m.reply msg.compact.delete_if(&:empty?).join(' :: ')
  end

  # get wiki page url and display summery
  def wiki(m, query)
    wiki_url = fetch("https://duckduckgo.com/html?q=#{CGI.escape '!wiki ' + query}").uri.to_s
    api_url = 'https://en.wikipedia.org/api/rest_v1/'
    uri = URI api_url + "page/summary/#{wiki_url[%r{([^/]+)/?$}]}"
    res = Net::HTTP.get uri
    m.reply "#{wiki_url} :: #{JSON.parse(res)['extract']}"
  end

  private

  def fetch(uri_str, limit = 10)
    raise 'too many HTTP redirects' if limit == 0

    response = Net::HTTP.get_response(URI(uri_str))

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection then
      location = response['location']
      fetch location, limit - 1
    else
      response.value
    end
  end
end
