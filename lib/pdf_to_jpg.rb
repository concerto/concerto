#takes in the path to a pdf file, outputs pdf_name.jpg.page_number to a tmp directory
def pdf_to_jpg(pdf_location)
  #location to write the jpg files to
  tmp_location = File.dirname(pdf_location)
  
  #name of the file, sans pdf extension
  file_name = File.basename(pdf_location, ".pdf")

  #array of JPG page files to be returned
  converted_jpgs = Array.new

  pdf = Magick::ImageList.new(pdf_location)

  pdf.each_with_index do |page, i|
    write_filename = tmp_location + "/" + file_name + "." + i.to_s + ".jpg"
    #write the JPG files to the directory specified
    pdf[i].write(write_filename)
    #appends full filename to array
    converted_jpgs << write_filename    
  end

  return converted_jpgs

end
