require 'bundler/setup'
Bundler.require(:default)

Dir.glob(File.join("{lib,models,controllers}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    enable :logging
    enable :sessions
  end

  DataMapper::Logger.new($stdout, :debug)
  DataMapper.finalize

  configure :development, :test do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/production.sqlite3")
    disable :run, :reload
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
