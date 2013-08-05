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

    #configs.uniq.pluck(:group, :id).each_with_index do |group, i|
    #  headers << "<li#{class_attribute if i == 0}><a href=\"#tab#{i}\" data-toggle=\"tab\">#{group}</a></li>"
    #end

    headers = ['<ul class="nav nav-tabs">']
    last_group = ""
    class_attribute = ' class="active"'

    configs.uniq.each_with_index do |c, i|
      if c.group != last_group
        headers << "<li#{class_attribute if i == 0}><a href=\"#tab#{c.id}\" data-toggle=\"tab\">#{c.group}</a></li>"
        last_group = c.group
      end
    end

    headers << '</ul>'
    headers.join.html_safe
  end

  # Check if the background processor is running or not
  # by looking at it's heartbeat and comparing it to a threshold.
  def background_processor_running?
    last_update = ConcertoConfig[:worker_heartbeat]
    threshold = Delayed::Worker.sleep_delay * 4
    return (Clock.time.to_i - last_update.to_i) < threshold
  end
end
