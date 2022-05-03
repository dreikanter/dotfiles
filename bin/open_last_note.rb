NOTES_PATH = File.join(Dir.home, 'Dropbox/Notes').freeze
EDITOR_PATH = '/usr/local/bin/subl'.freeze

wildcard = File.join(NOTES_PATH, '**', '*.md')
last_note_path = Dir.glob(wildcard).grep(%r{\d+/\d{2}/.*\.md}).max
system("#{EDITOR_PATH} --add #{NOTES_PATH} #{last_note_path}")
