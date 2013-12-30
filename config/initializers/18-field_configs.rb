# An array of hashes of all the possible field configs
# Each entry has:
#  the fieldconfig name (a string)
#  the type of data it represents (boolean, text, select, checkbox) 
#  and its possible values (array of values)

#start an empty array
field_configs_array = []


#put the dictionary hash into the Application object for global access
Concerto::Application.config.field_configs = {
  :transition => {:type => :select, :values => ['fade','slide','replace']}, 
  :time_format => {:type => "string"},
  :url_parms => {:type => "string"}
}
