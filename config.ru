require 'bundler/setup'
Bundler.require(:default)

configure do
  # set :sessions, true
  # set :logging, true
  # set :environment, :production
end

require './app'

run App.new
