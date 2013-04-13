# http://blog.crowdint.com/2011/04/06/sinatra-haml-compass-blueprint.html
# https://github.com/davidklaw/foundation-sinatra

require 'bundler/setup'
Bundler.require(:default)

require  File.dirname(__FILE__) + "/app.rb"

run App
