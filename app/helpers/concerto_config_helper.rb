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

    configs.uniq.each_with_index do |c, i|
      if c.category != last_category
        headers << "<li#{class_attribute if i == 0}><a href=\"#tab#{c.id}\" data-toggle=\"tab\">#{c.category}</a></li>"
        last_category = c.category
      end
    end

    headers << '</ul>'
    headers.join.html_safe
  end
end
