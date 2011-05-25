# based on http://archive.alwaysmovefast.com/cracking-captchas-for-fun-and-profit.html

require 'mini_magick'
require 'chunky_png'

# create tmp folder for storing processed images
directory_name = Dir::pwd + "/" + "tmp"
unless FileTest::directory?(directory_name)
  Dir::mkdir(directory_name)
end

# convert jpg to png
image = MiniMagick::Image.open('captcha.jpg')
image.format 'png'
image.write directory_name + '/captcha.png'

# convert color to grayscale
image = ChunkyPNG::Image.from_file('captcha.png')
image.height.times do |y|
  image.row(y).each_with_index do |pixel, x|
	image[x,y] = ChunkyPNG::Color.to_grayscale(pixel)
  end
end

# convert light pixel to white pixel to remove noise
image.height.times do |y|
  image.row(y).each_with_index do |pixel, x|
    if pixel > ChunkyPNG::Color.to_grayscale(ChunkyPNG::Color.rgb(200 , 200, 200))
	  image[x,y] = ChunkyPNG::Color.rgb(255, 255, 255)
	end
  end
end

image.save(directory_name + '/captcha_processed_1.png')

# "skeletonize"
height, weight = image.dimension
# "skeletonize" first pass
image.height.times do |y|
  image.row(y).each_with_index do |pixel, x|
    count = 0
    if pixel != ChunkyPNG::Color.rgb(255, 255, 255)
	  if image[x-1,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x-1,y] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x-1,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x+1,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x+1,y] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x+1,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  if image[x,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
	    count += 1
	  end
	  
	  if count < 6
	    image[x,y] = ChunkyPNG::Color.rgb(1, 1, 1)
      end
	end
  end
end

image.save(directory_name + '/captcha_processed_2.png')

# "skeletonize second pass
image.height.times do |y|
  image.row(y).each_with_index do |pixel, x|
    if pixel > ChunkyPNG::Color.rgb(1 , 1, 1)
	  image[x,y] = ChunkyPNG::Color.rgb(255, 255, 255)
	end
  end
end

image.save(directory_name + '/captcha_processed_3.png')

# splitting characters
started = false;
letters = Array.new
bottomY, topY = 0, height
firstX, lastX = 0, 0
image.width.times do |x|
  black_pixel_in_col = false
  image.column(x).each_with_index do |pixel, y|
    if pixel != ChunkyPNG::Color.rgb(255, 255, 255)
	  unless started
	    started = true
		firstX = x
		lastX = x
	  end
	  
	  if y > bottomY
	    bottomY = y
	  end
	  
	  if y < topY
	    topY = y
	  end
	  
	  puts lastX
	  if x > lastX
	    lastX = x
	  end
	  
	  black_pixel_in_col = true
	end
  end
  if !black_pixel_in_col and started
    letters << image.crop(firstX, topY, lastX-firstX, bottomY-topY)
    started = false
    bottomY = 0
    topY = height
  end
end

# saving each of those letter images into tmp files
i = 0
letters.each { |letter|
  fixed_image = ChunkyPNG::Image.new(15, 15, ChunkyPNG::Color::WHITE)
  fixed_image.compose! letter
  fixed_image.save(directory_name + '/' + i.to_s + '.png')
  i += 1
}
