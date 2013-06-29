module DashboardHelper  
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

    headers = []
    last_group = ""
    headers << '<ul class="nav nav-tabs">'
    i = 0
    configs.each do |c|
      if c.group != last_group
        class_attribute = (i == 0 ? ' class="active"' : '')
        i += 1
        headers << "<li#{class_attribute}><a href=\"#tab#{c.id}\" data-toggle=\"tab\">#{c.group}</a></li>"
        last_group = c.group
      end
    end
    headers << '</ul>'

    return headers.join().html_safe
  end
end