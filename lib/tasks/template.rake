namespace :template do
  desc "copy a concerto template"
  task :copy, [:source_name, :destination_name] => :environment do |task, args|
    if args.source_name.blank?
      puts "a source template name is required"
    elsif args.destination_name.blank?
      puts "a destination template name is required"
    else
      source = Template.find_by(name: args.source_name)
      destination = Template.find_by(name: args.destination_name)

      if source.blank?
        puts "cannot find source template"
      elsif !destination.blank?
        puts "a destination template with that name already exists"
      else
        destination = source.dup
        destination.name = args.destination_name
        source.media.each do |m|
          new_media = m.dup
          new_media.attachable_id = nil

          unless m.file_contents.blank?
            t = Tempfile.new(m.id.to_s, encoding: m.file_contents.encoding)
            t.write(m.file_contents)
            new_media.file = t
            t.close
          end
          destination.media << new_media
        end
        source.positions.each do |p|
          new_position = p.dup
          destination.positions << p
        end

        if destination.save
          puts "new template id is #{destination.id}"
          destination.create_activity key: "template.copy", params: { template_name: args.destination_name, from: args.source_name }
        else
          puts destination.errors.full_messages.join(", ")
        end
      end
    end
  end

end
