def load_mapping(object)
  require 'csv'
  mapping = {}
  CSV.foreach('mapping.csv') do |row|
    obj, old_id, new_id = row
    if obj != object
      next
    else
      mapping[old_id.to_i] = new_id.to_i
    end
  end
  return mapping
end

def save_mapping(object, mapping, filename='mapping.csv')
  require 'csv'
  CSV.open(filename, 'ab') do |csv|
    mapping.each do |old_id, new_id|
      csv << [object, old_id, new_id]
    end
  end  
end

namespace :import do
  desc 'Import V1 Users.'
  task :users => :environment do
    require 'legacy_schema'
    mapping = {}
    ActiveRecord::Base.transaction do
      V1User.all.each do |u|
        first, last = u.name.split(' ', 2)

        new_user = User.new(
          :email => u.email,
          :is_admin => u.admin_privileges,
          :first_name => first,
          :last_name => last,
          :password => u.email,
          :password_confirmation => u.email
        )
        if new_user.save
          mapping[u.id] = new_user.id
          #puts "Created User - #{new_user.name} (#{new_user.id})"
        else
          puts "Error with User #{new_user.name}\n #{new_user.errors.to_yaml}"
        end
      end
      save_mapping('user', mapping)
    end
  end

  desc 'Import V1 Groups.'
  task :groups => :environment do
    require 'legacy_schema'
    mapping = {}
    ActiveRecord::Base.transaction do
      V1Group.all.each do |g|
        new_group = Group.new(
          :name => g.name
        )
        if new_group.save
          mapping[g.id] = new_group.id
          #puts "Created Group - #{new_group.name} (#{new_group.id})"
        else
          puts "Error with Group #{new_group.name}\n #{new_group.errors.to_yaml}"
        end
      end
      save_mapping('group', mapping)
    end
  end

  desc 'Import V1 Group Memberships.'
  task :memberships => :environment do
    require 'legacy_schema'
    groups = load_mapping('group')
    users = load_mapping('user')
    ActiveRecord::Base.transaction do
      V1Group.all.each do |g|
        g.users.each do |u|
          new_membership = Membership.new(
            :user_id => users[u.id],
            :group_id => groups[g.id],
            :level => Membership::LEVELS[:leader]
          )
          if new_membership.save
            #puts "Linked user with group."
          else
            puts "Error with Membership #{new_membership.errors.to_yaml}"
          end
        end
      end
    end
  end

  desc 'Import V1 Feeds.'
  task :feeds => :environment do
    require 'legacy_schema'
    mapping = {}
    groups = load_mapping('group')
    ActiveRecord::Base.transaction do
      V1Feed.all.each do |f|
        f_type = f.read_attribute_before_type_cast('type').to_i
        if (f_type == 1 || f_type == 4)
          puts "Skipping #{f.name} - Dynamic looking feed."
          next
        end
        submit = true
        subscribe = true
        if f_type == 2
          submit = false
        elsif f_type == 3
          submit = false
          subscribe = false
        end
        new_feed = Feed.new(
          :name => f.name,
          :description => f.description,
          :group_id => groups[f.group.id],
          :is_viewable => subscribe,
          :is_submittable => submit
        )
        if new_feed.save
          mapping[f.id] = new_feed.id
          #puts "Created feed #{new_feed.name} (#{new_feed.id})"
        else
          puts "Error with Feed #{new_feed.name}\n #{new_feed.errors.to_yaml}"
        end
      end
      save_mapping('feed', mapping)
    end
  end

  desc 'Import Content.'
  task :content => :environment do
    require 'legacy_schema'
    users = load_mapping('user')
    existing_content = load_mapping('content')
    kinds = {}
    V1Type.all.each do |t|
       kind = Kind.where(:name => t.name).first
       if !kind.nil?
         kinds[t.id] = kind.id
       else
         puts "No mapping Kind found for #{t.name}."
       end
    end
    V1Content.all.each do |c|
      if !existing_content.include?(c.id)
        ActiveRecord::Base.transaction do
          content_type = nil
          if c.mime_type.include?('image')
            content_type = Graphic
          elsif c.mime_type == 'text/plain'
            content_type = Ticker
          end
          if !content_type.nil?
            new_content = content_type.new(
              :name => c.name,
              :user_id => users[c.user_id],
              :duration => (c.duration/1000).to_i,
              :start_time => c.start_time,
              :end_time => c.end_time,
              :created_at => c.submitted,
              :kind_id => kinds[c.type_id]
            )
            if content_type == Ticker
              new_content.data = c.content
            end
            if content_type == Graphic
              filename = "#{ENV['CONTENT_DIR']}/#{c.content}"
              if !File.exists?(filename)
                puts "Missing file: #{filename} for content #{c.id}"
                next
              end
              file = File.new(filename, 'r')
              new_content.media.build(:key => 'original', :file => file, :file_type => c.mime_type)
            end
            new_content.save
            save_mapping('content', {c.id => new_content.id})
            #puts new_content.to_yaml
          else
            puts "Unable to find Content Class for #{c.id} - #{c.name}."
          end
        end
      end
    end
  end

  desc 'Import Submissions.'
  task :submissions => :environment do
    require 'legacy_schema'
    users = load_mapping('user')
    content = load_mapping('content')
    feeds = load_mapping('feed')
    V1Submission.all.each do |s|
      ActiveRecord::Base.transaction do
        if !content.include?(s.content_id) || content[s.content_id] == 0
          #puts "Content missing or invalid."
          next
        end
        if !feeds.include?(s.feed_id)
          #puts "Feed missing."
          next
        end
        if s.moderator_id == 0 || (!s.moderation_flag.nil? && s.moderator_id.nil?)
          #puts "Unknown moderator.  Skipping."
          next
        end
        submission = Submission.new(
          :feed_id => feeds[s.feed_id],
          :content_id => content[s.content_id],
          :moderator_id => users[s.moderator_id],
          :moderation_flag => s.moderation_flag,
          :duration => (s.duration/1000).to_i
        )
        if submission.save
          #puts "Content #{submission.content_id} + Feed #{submission.feed_id}."
        else
          puts submission.errors.to_yaml
        end
      end
    end
  end

  desc 'Import Templates.'
  task :templates => :environment do
    require 'legacy_schema'
    template_mapping = {}
    position_mapping = {}
    temp_position_mapping = {}
    ActiveRecord::Base.transaction do
      V1Template.all.each do |t|
        new_template = Template.new(
          :name => t.name,
          :author => t.creator,
          :updated_at => t.modified,
          :original_width => t.width,
          :original_height => t.height,
          :is_hidden => t.hidden
        )
        t.fields.each do |f|
          position = new_template.positions.build
          position.style = f.style
          position.top = f.top
          position.left = f.left
          position.width = f.width
          position.height = f.height
          position.field = Field.where(:name => f.type.name).first
          temp_position_mapping[f.id] = position
        end
        filename = "#{ENV['TEMPLATE_DIR']}/#{t.filename}"
        if !File.exists?(filename)
          puts "Missing file: #{filename} for template #{t.id}"
          next
        end
        file = File.new(filename, 'r')
        new_template.media.build(:key => 'original', :file => file, :file_type => 'image/jpeg')
        if new_template.save
          template_mapping[t.id] = new_template.id
          temp_position_mapping.each do |id, pos|
            position_mapping[id] = pos.id
          end
          temp_position_mapping = {}
          #puts "Created template."
        else
          puts "Error with Template #{new_template.errors.to_yaml}"
        end
      end
      save_mapping('template', template_mapping)
      save_mapping('position', position_mapping)
    end
  end

  desc 'Import V1 Screens.'
  task :screens => :environment do
    require 'legacy_schema'
    mapping = {}
    groups = load_mapping('group')
    templates = load_mapping('template')
    ActiveRecord::Base.transaction do
      V1Screen.all.each do |s|
        new_screen = Screen.new(
          :name => s.name,
          :location => s.location,
          :is_public => !s.type?,
          :template_id => templates[s.template_id]
        )
        new_screen.owner = Group.find(groups[s.group_id])
        if new_screen.save
          mapping[s.id] = new_screen.id
          #puts "Created Screen - #{new_screen.name} (#{new_screen.id})"
        else
          puts "Error with Screen #{new_screen.name}\n #{new_screen.errors.to_yaml}"
        end
      end
      save_mapping('screen', mapping)
    end
  end

  desc 'Import V1 Subscriptions.'
  task :subscriptions => :environment do
    require 'legacy_schema'
    mapping = {}
    screens = load_mapping('screen')
    position_mapping = load_mapping('position')
    feeds = load_mapping('feed')
    ActiveRecord::Base.transaction do
      V1Screen.all.each do |s|
        s.template.fields.each do |v1_field|
          positions = V1Subscription.where(:field_id => v1_field.id, :screen_id => s.id)
          positions.each do |p|
            new_subscription = Subscription.new(
              :screen_id => screens[s.id],
              :weight => p.weight
            )
            if !position_mapping.include?(p.field_id)
              puts "Unable to find position for this subscription.  Skipping"
              next
            end
            if !feeds.include?(p.feed_id)
              puts "Unable to find feed #{p.feed.name} for this subscription.  Skipping"
              next
            end
            new_position = Position.find(position_mapping[p.field_id])
            new_subscription.field_id = new_position.field.id
            new_subscription.feed_id = feeds[p.feed_id]
            if new_subscription.save
              #puts "Created subscription."
            else
              puts "Error with subscription #{new_subscription.errors.to_yaml}"
            end
          end
        end
      end
    end
  end
end

