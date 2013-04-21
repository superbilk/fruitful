require 'bundler/setup'
Bundler.require(:default)

Dir.glob(File.join("{lib,models,controllers}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial

  DataMapper::Logger.new($stdout, :debug)
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
  DataMapper.finalize
  # DataMapper.auto_migrate!

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    enable :logging
    enable :sessions
  end

  configure :development do
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper.auto_migrate!
  end

  get "/" do
    haml :index, :layout_engine => :erb
  end

  post "/up" do
    Vote.create(:vote => 1)
  end

  post "/down" do
    Vote.create(:vote => -1)
  end

  get "/statistic" do
    @votes = Vote.all(:order => [ :created_at.desc ])
    haml :statistic, :layout_engine => :erb
  end

end
