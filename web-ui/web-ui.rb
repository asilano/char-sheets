require 'sinatra'

require 'sinatra/reloader'

require_relative '../lib/dnd5e'

get '/' do
  # Fetch a list of available character files
  @charnames = character_list
  erb :index
end

get '/:name/show' do |name|
  @character = Character.load(name)
  erb :"char-sheets/#{@character.template_name}"
end

def character_list
  files = Dir.glob(File.join(__dir__, '../characters/*.char'))
  files.map { |fn| File.basename(fn, '.char') }
end
