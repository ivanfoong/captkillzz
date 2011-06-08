#!/usr/bin/env ruby
# requires ImageMagick
# - view http://www.imagemagick.org/script/binary-releases.php#macosx
# - or
# - port install imagemagick
# gem install mini_magick chunky_png

require 'rubygems'
require 'mini_magick'
require 'chunky_png'

usage = "usage:  preprocess_image.rb image_filename.. \n" +
  "  works with any number of image_filename"

@white_threshold = 90 #0-255

def time
  start = Time.now
  yield
  processed_seconds = Time.now - start
  puts "Processed for #{processed_seconds} seconds"
end

def preprocess_image(filename)
  # convert jpg to png
  image = MiniMagick::Image.open(filename)
  image.format 'png'
	image.write "#{filename}.png"
	
	# convert color to grayscale
	image = ChunkyPNG::Image.from_file("#{filename}.png")
	image.height.times do |y|
		image.row(y).each_with_index do |pixel, x|
		image[x,y] = ChunkyPNG::Color.to_grayscale(pixel)
		end
	end
	
	# convert grayscale to black or white
	image.height.times do |y|
		image.row(y).each_with_index do |pixel, x|
			if pixel > ChunkyPNG::Color.to_grayscale(ChunkyPNG::Color.rgb(@white_threshold ,@white_threshold, @white_threshold))
				image[x,y] = ChunkyPNG::Color.rgb(255, 255, 255)
			else
				image[x,y] = ChunkyPNG::Color.rgb(0, 0, 0)
			end
		end
	end
	
	output_filename = "bw_#{filename}.png"
	image.save output_filename
	puts "Processed #{filename} and created the processed image, #{output_filename}"
end

if ARGV.size != 1
  puts usage
  exit!
end

time do
	ARGV.each do |filename|
		preprocess_image(filename)
	end
end

=begin # for multi-threading
time do
  thread_arr = []
	ARGV.each do |filename|
		thread_arr << Thread.new {
		  puts "Starting Thread"
		  preprocess_image(filename)
		}
	end
	
	thread_arr.each { |thread| 
    thread.join
    puts "Completed Thread"
  }
end
=end