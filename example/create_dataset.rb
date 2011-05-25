# based on http://archive.alwaysmovefast.com/cracking-captchas-for-fun-and-profit.html

# require creating the directory "training_dataset"
# and adding the training dataset images in that folder
# with the filename ???.jpg where ? represent the the training image digit in sequence

require 'mini_magick'
require 'chunky_png'

# create tmp folder for storing processed images
tmp_directory_name = Dir::pwd + "/" + "tmp"
unless FileTest::directory?(tmp_directory_name)
  Dir::mkdir(tmp_directory_name)
end

i = 0
Dir.chdir('training_dataset')
Dir.glob('*') { |file|
  
  # convert jpg to png
  puts 'loading ' + file
  image = MiniMagick::Image.open(file)
  image.format 'png'
  image.write tmp_directory_name + '/captcha.png'

  # convert color to grayscale
  image = ChunkyPNG::Image.from_file tmp_directory_name + '/captcha.png'
  image.height.times do |y|
    image.row(y).each_with_index do |pixel, x|
      image[x,y] = ChunkyPNG::Color.to_grayscale(pixel)
    end
  end

  # convert light pixel to white pixel to remove noise
  image.height.times do |y|
    image.row(y).each_with_index do |pixel, x|
      if pixel > ChunkyPNG::Color.to_grayscale(ChunkyPNG::Color.rgb(190 , 190, 190))
        image[x,y] = ChunkyPNG::Color.rgb(255, 255, 255)
  	  end
    end
  end

  image.save(tmp_directory_name + '/captcha_processed_1.png')

  # "skeletonize"
  width, height = image.dimension
  # "skeletonize" first pass
  image.height.times do |y|
    image.row(y).each_with_index do |pixel, x|
      count = 0
      if pixel != ChunkyPNG::Color.rgb(255, 255, 255)
        if x > 0 and y > 0 and image[x-1,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
	      count += 1
        end
        if x > 0 and image[x-1,y] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if x > 0 and y < height-1 and image[x-1,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if y < height-1 and image[x,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if x < width-1 and y < height-1 and image[x+1,y+1] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if x < width-1 and image[x+1,y] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if x < width-1 and y > 0 and image[x+1,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
        if y > 0 and image[x,y-1] != ChunkyPNG::Color.rgb(255, 255, 255)
          count += 1
        end
	  
        if count < 6
          image[x,y] = ChunkyPNG::Color.rgb(1, 1, 1)
        end
      end
    end
  end

  image.save(tmp_directory_name + '/captcha_processed_2.png')

  # "skeletonize second pass
  image.height.times do |y|
    image.row(y).each_with_index do |pixel, x|
      if pixel > ChunkyPNG::Color.rgb(1 , 1, 1)
        image[x,y] = ChunkyPNG::Color.rgb(255, 255, 255)
      end
    end
  end

  image.save(tmp_directory_name + '/captcha_processed_3.png')

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
	    
        if x > lastX
          lastX = x
        end
	  
        black_pixel_in_col = true
      end
    end
    if !black_pixel_in_col and started
	  if lastX-firstX > 5 # if letter is greater than 5 pixel width
        letters << image.crop(firstX, topY, lastX-firstX, bottomY-topY)
      end
      started = false
      bottomY = 0
      topY = height
    end
  end

  # saving each of those letter images into dataset folders
  [0,1,2].each { |index|
    if letters.size > index
      char = file[index, 1]
      fixed_image = ChunkyPNG::Image.new(20, 30, ChunkyPNG::Color::WHITE)
      fixed_image.compose! letters[index]
	  dataset_directory_name = Dir::pwd + '/../dataset/'
	  unless FileTest::directory?(dataset_directory_name)
        Dir::mkdir(dataset_directory_name)
      end
	  
      dataset_sub_directory_name = dataset_directory_name + char + '/'
	  unless FileTest::directory?(dataset_sub_directory_name)
        Dir::mkdir(dataset_sub_directory_name)
      end
	  output_filename = dataset_sub_directory_name  + i.to_s + '.png'
	  puts 'writing to ' + output_filename
      fixed_image.save(output_filename)
    end
  }
  i += 1
}
