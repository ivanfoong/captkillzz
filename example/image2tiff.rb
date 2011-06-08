require 'rubygems'
require 'mini_magick'

def image2tiff(in_filename)
	image = MiniMagick::Image.open(in_filename)
	image.format 'tiff'
	image.write "#{in_filename}.tiff"
end

ARGV.each do |filename|
	image2tiff(filename)
end