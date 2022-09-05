#!/usr/bin/env ruby

NOTES_PATH = File.join(Dir.home, 'Dropbox/Notes').freeze

wildcard = File.join(NOTES_PATH, '**', '*.md')
last_note_path = Dir.glob(wildcard).grep(%r{\d+/\d{2}/.*\.md}).max
system("subl --add #{NOTES_PATH} #{last_note_path}")
