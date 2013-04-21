# http://blog.crowdint.com/2011/04/06/sinatra-haml-compass-blueprint.html
# https://github.com/davidklaw/foundation-sinatra

set :environment, ENV['RACK_ENV'].to_sym
disable :run, :reload

root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )

run App.new
