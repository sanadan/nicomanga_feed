#!/usr/bin/env ruby

puts( 'Content-type: application/atom+xml' )
puts()
puts( File.read( 'feed.xml' ) )

