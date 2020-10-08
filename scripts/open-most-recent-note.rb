NOTES_PATH = File.join(Dir.home, 'Dropbox/Notes').freeze
LAST_FILE = Dir["#{NOTES_PATH}/*.md"].sort.last.freeze
EDITOR_PATH = '/usr/local/bin/subl'.freeze

if LAST_FILE.nil?
  puts 'Notes directory is empty'
elsif if system("#{EDITOR_PATH} --add #{NOTES_PATH} #{LAST_FILE}")
  puts "#{File.basename(LAST_FILE)} is the last one"
else
  puts 'Error creating a file :('
end
