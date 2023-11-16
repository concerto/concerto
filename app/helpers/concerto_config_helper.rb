module ConcertoConfigHelper
  def generate_tabs configs
    # <div class="tabbable tabs-left">
    #   <ul class="nav nav-tabs">
    #     <li class="active">
    #       <a href="#tab1" data-toggle="tab">Group 1</a>
    #     </li>
    #     <li>
    #       <a href="#tab2" data-toggle="tab">Group 2</a>
    #     </li>
    #   </ul>
    # </div>

    headers = ['<ul class="nav nav-tabs">']
    last_category = ""
    class_attribute = ' class="active"'

    configs.distinct.each_with_index do |c, i|
      if c.category != last_category
        headers << "<li#{class_attribute if i == 0}><a href=\"#tab#{c.id}\" data-toggle=\"tab\">#{c.category}</a></li>"
        last_category = c.category
      end
    end

    headers << '</ul>'
    headers.join.html_safe
  end
  
  def test_symbol(test_boolean)
    "<i class='fas fa-#{test_boolean ? "check-square" : "exclamation-triangle"} #{test_boolean ? "is_approved" : "is_denied"} fa-lg'></i> &nbsp;".html_safe
  end
    
  def imagemagick_text
    "ImageMagick is #{@imagemagick_installed ? "installed" : "not installed"} at #{which("convert")}"
  end
  
  def rmagick_text
    "RMagick is #{@rmagick_installed ? "installed" : "not installed"}"
  end
  
  def world_writable_text
    @not_world_writable ? "The Concerto directory is not world writable" : "The Concerto directory is world writable"
  end
  
  def root_perms_text
    "#{Rails.root} has permission #{File.stat(Rails.root).mode.to_s(8)[-3,3]}" + "#{@rails_root_perms == 700 ? "" : " instead of 700"}"
  end
  
  def rails_log_text
    "#{Rails.root.join('log')} has permission #{File.stat(Rails.root.join('log')).mode.to_s(8)[-3,3]}" + "#{@rails_log_perms == 600 ? "" : " instead of 600"}"
  end
  
  def rails_tmp_text
    Rails.root.join('tmp').to_s + " " + (@rails_tmp_perms ? "is" : "should be") + " writable by the webserver."
  end
  
  def webserver_ownership_text
    Rails.root.to_s + (@webserver_ownership ? " is owned by the webserver" : " is not owned by the webserver")
  end
  
  def db_text
    adapter = ActiveRecord::Base.configurations[Rails.env]['adapter']
    if @not_using_sqlite == false && (system_has_mysql? && system_has_postgres?)
      "#{adapter} is your current database adapter. It's not recommended for production deployments and both MySQL (#{mysql_location}) and Postgresql (#{postgres_location}) are available on your system."
    elsif @not_using_sqlite == false && system_has_mysql?
      "#{adapter} is your current database adapter. It's not recommended for production deployments and MySQL is installed at #{mysql_location}"
    elsif @not_using_sqlite == false && system_has_postgres?
      "#{adapter} is your current database adapter. It's not recommended for production deployments and Postgresql is installed at #{postgres_location}"
    else
      "#{adapter} is properly installed"
    end
  end
  
end
