require 'wx'

class MyFrame < Wx::Frame
  
  def initialize
    super(nil, :title => 'Training', :size => Wx::Size.new(60, 140))
	
	check_more_training()
    
    @main_sizer = Wx::BoxSizer.new Wx::VERTICAL
	@display = ImageDisplay.new self
	begin
      image = Wx::Bitmap.new(@filename)
      if image.is_ok
        @display.set_image image
      end
    rescue Exception # catch any problems in setting up the bitmap
      return 
    end
    @main_sizer.add(@display, 1, Wx::GROW|Wx::ALL, 0)
	
	@my_textbox = Wx::TextCtrl.new(self, -1, '')
	evt_text_enter(@my_textbox.get_id) { | event | submit(event) }
	@main_sizer.add(@my_textbox, 0, Wx::GROW|Wx::ALL, 2)
	@my_textbox.set_focus()
	
	@my_button = Wx::Button.new(self, -1, 'Submit')
	evt_button(@my_button.get_id()) { |event| submit(event)}
	@main_sizer.add(@my_button, 0, Wx::GROW|Wx::ALL, 2)

    set_sizer @main_sizer
  end
  
  def get_unknown_image_filename()
    Dir.glob('raw_dataset/*') { |file|
	  return file
	}
  end
  
  def submit(event)
    letters = @my_textbox.get_value()
	@my_textbox.set_value('')
	
	directory_name = Dir::pwd + "/" + "training_dataset"
    unless FileTest::directory?(directory_name)
      Dir::mkdir(directory_name)
    end
	
	new_filename = "#{directory_name}/#{letters}.jpg"
	File.rename(@filename, new_filename)
	check_more_training()
	begin
      image = Wx::Bitmap.new(@filename)
      if image.is_ok
        @display.set_image image
      end
    rescue Exception # catch any problems in setting up the bitmap
      return 
    end
  end
  
  def check_more_training()
    @filename = get_unknown_image_filename()
	
	unless @filename
	  md = Wx::MessageDialog.new(nil, "No more dataset to be identified", "Hurray!", Wx::ICON_INFORMATION)
      md.show_modal
	  self.close()
	end
  end
end

class ImageDisplay < Wx::ScrolledWindow
 def initialize parent
   super parent
   @image = nil
 end

 def set_image image
   @image = image
   refresh
 end

 def on_draw dc
   dc.set_background Wx::WHITE_BRUSH
   dc.clear
   return if @image == nil
   dc.draw_bitmap(@image, 0, 0, true)
 end
end

Wx::App.run do
  MyFrame.new.show
end