# An array of hashes of all the possible field configs
# Each entry has:
#  the fieldconfig name (a string)
#  the type of data it represents (boolean, text, select, checkbox) 
#  and its possible values (comma seperated strings)

#start an empty array
field_configs_array = []

#set up each hash and push it onto the end of the array

#Transition
hash = { :name => :transition, :type => :select, :values => "fade,slide,replace" }
field_configs_array.push(hash)

#Format
hash = { :name => :time_format, :type => :text, :values => "" }
field_configs_array.push(hash)
 
#shove all of this into the Application object for global access
Concerto::Application.config.field_configs = field_configs_array

