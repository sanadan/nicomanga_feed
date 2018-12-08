#!/usr/bin/env ruby

require 'rss'
require 'mechanize'

TITLE = '新着 - ニコニコ静画（マンガ）'.freeze
URL = 'http://seiga.nicovideo.jp/manga/list?sort=manga_created'.freeze
ABOUT = URL
DESCRIPTION = 'ニコニコ静画（マンガ）の新着をFeedにします。'.freeze
AUTHOR = 'sanadan'.freeze

@items = []
@web = Mechanize.new

def link(data)
  URI.join('http://seiga.nicovideo.jp', data.at('.title a')['href']).to_s
end

def content(data, item)
  author = data.at('.mg_author').text
  thumbnail = data.at('.comic_icon img')['src']
  content = "<a href=\"#{item['link']}\">"
  content += "<img src=\"#{thumbnail}\" border=\"0\">"
  content += "#{item['title']}</a> / #{author}"
  content
end

def main
  page = @web.get(URL)

  page.search('.item_container').each do |data|
    item = {}
    item['link'] = link(data)
    item['title'] = data.at('.title a').text
    item['content'] = content(data, item)
    item['date'] = Time.now

    @items << item
  end

  raise '検索結果が正しく取得できませんでした' if @items.empty?
end

# entry
begin
  main
rescue StandardError
  item = {}
  item['id'] = Time.now.strftime('%Y%m%d%H%M%S')
  item['title'] = $ERROR_INFO.to_s
  item['content'] = $ERROR_INFO.to_s
  $ERROR_INFO.backtrace.each do |trace|
    item['content'] += '<br>'
    item['content'] += trace
  end
  item['date'] = Time.now
  @items << item
end

feed = RSS::Maker.make('atom') do |maker|
  maker.channel.about = ABOUT
  maker.channel.title = TITLE
  maker.channel.description = DESCRIPTION
  maker.channel.link = URL
  maker.channel.updated = Time.now
  maker.channel.author = AUTHOR
  @items.each do |data|
    item = maker.items.new_item
    item.id = data['id']
    item.title = data['title']
    item.link = data['link'] if data['link']
    item.content.content = data['content']
    item.content.type = 'html'
    item.date = data['date']
  end
end

File.write(__dir__ + '/html/feed.xml', feed)
# print feed
