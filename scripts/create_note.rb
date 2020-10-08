require 'fileutils'

NOTES_PATH = File.join(Dir.home, 'Dropbox/Notes').freeze
EDITOR_PATH = '/usr/local/bin/subl'.freeze

def new_note_name(time, uniq_index)
  suffix = uniq_index.positive? ? "_#{uniq_index}" : ''
  File.join(notes_directory(time), "#{time.strftime('%Y-%m-%d')}#{suffix}.md")
end

def notes_directory(time)
  File.join(NOTES_PATH, time.strftime('%Y'), time.strftime('%m'))
end

def unique_new_note_name(time)
  uniq_index = 0

  loop do
    file_name = new_note_name(time, uniq_index)
    return file_name unless File.exist?(file_name)
    uniq_index += 1
  end
end

now = Time.now
full_path = unique_new_note_name(now)
FileUtils.mkdir_p(notes_directory(now))
system("#{EDITOR_PATH} --add #{NOTES_PATH} #{full_path}")
