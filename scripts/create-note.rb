NOTES_PATH = File.join(Dir.home, 'Dropbox/Notes').freeze
EDITOR_PATH = '/usr/local/bin/subl'.freeze

def new_note_name(index)
  suffix = (index > 0) ? "_#{index}" : ''
  File.join(NOTES_PATH, "#{Time.now.strftime('%Y-%m-%d')}#{suffix}.md")
end

def unique_new_note_name
  index = 0
  loop do
    file_name = new_note_name(index)
    return file_name unless File.exist?(file_name)
    index += 1
  end
end

full_path = unique_new_note_name

if system("#{EDITOR_PATH} --add #{NOTES_PATH} #{full_path}")
  puts "#{File.basename(full_path)} created :)"
else
  puts 'Error creating a new note file :('
end
