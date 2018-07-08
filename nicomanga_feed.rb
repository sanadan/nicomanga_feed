#!/usr/bin/env ruby

require 'rss'
require 'mechanize'

$title = '新着 - ニコニコ静画（マンガ）'
$uri = 'http://seiga.nicovideo.jp/manga/list?sort=manga_created'
$about = $uri
$description = 'ニコニコ静画（マンガ）の新着をFeedにします。'
$author = 'sanadan'

def main
  web = Mechanize.new
  page = web.get( $uri )

  page.search( '.item_container' ).each do |data|
    item = {}
    item[ 'link' ] = URI.join( 'http://seiga.nicovideo.jp', data.at( '.title a' )[ 'href' ] ).to_s
    item[ 'title' ] = data.at( '.title a' ).text
    author = data.at( '.mg_author a' ).text
    thumbnail = data.at( '.comic_icon img' )[ 'src' ]
    item[ 'content' ] = "<a href=\"#{item[ 'link' ]}\"><img src=\"#{thumbnail}\" border=\"0\">#{item[ 'title' ]}</a> / #{author}"
    item[ 'date' ] = Time.now

    $items << item
  end

  raise "検索結果が正しく取得できませんでした" if $items.size == 0
end

# entry
$items = []
begin
  main
rescue
  item = {}
  item[ 'id' ] = Time.now.strftime( '%Y%m%d%H%M%S' )
  item[ 'title' ] = $!.to_s
  item[ 'content' ] = $!.to_s
  $!.backtrace.each do |trace|
    item[ 'content' ] += '<br>'
    item[ 'content' ] += trace
  end
  item[ 'date' ] = Time.now
  $items << item
end

feed = RSS::Maker.make( 'atom' ) do |maker|
  maker.channel.about = $about
  maker.channel.title = $title
  maker.channel.description = $description
  maker.channel.link = $uri
  maker.channel.updated = Time.now
  maker.channel.author = $author
  $items.each do |data|
    item = maker.items.new_item
    item.id = data[ 'id' ]
    item.title = data[ 'title' ]
    item.link = data[ 'link' ] if data[ 'link' ]
    item.content.content = data[ 'content' ]
    item.content.type = 'html'
    item.date = data[ 'date' ]
  end
end

File.write( '/var/www/nicomanga_feed/html/feed.xml', feed )
#print feed

