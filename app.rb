require 'bundler/setup'
Bundler.require(:default)

require 'securerandom'
require './pwgen'

Dir.glob(File.join("{lib,models,controllers,routes}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    enable :logging
    enable :sessions
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.finalize

  configure :development, :test do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/production.sqlite3")
    DataMapper.auto_upgrade!
    disable :run, :reload
  end

  before do
    @account = Account.new(:name => "Sample User", :url => "")
  end

  get "/" do
    haml :index, :layout_engine => :erb
  end

  post "/up" do
    @account = Account.first(:url => URI.escape(params[:url]))
    vote = Vote.new(:vote => 1)
    vote.account = @account
    vote.save
  end

  post "/down" do
    @account = Account.first(:url => URI.escape(params[:url]))
    vote = Vote.new(:vote => -1)
    vote.account = @account
    vote.save
  end

  get "/votes_count.json" do
    content_type :json
    Vote.count.to_json
  end

  get "/accounts_count.json" do
    content_type :json
    Account.count.to_json
  end

  get "/graph.json" do
    content_type :json
    limit = (URI.escape(params[:width]).to_i/5).ceil + 3
    if URI.escape(params[:url]).empty?
      votes = Vote.all(:account_id => nil, :order => [ :created_at.desc ], :limit => limit)
    else
      @account = Account.first(:url => URI.escape(params[:url]))
      votes = Vote.all(:account_id => @account.id, :order => [ :created_at.desc ], :limit => limit)
    end
    @votes = Array.new
    votes.each do |vote|
      @votes << vote.vote
    end
    @votes = @votes.drop(3)
    @votes.to_json
  end

  get "/new" do
    pwgen = PasswordGenerator.new
    newUrl = pwgen.generate(8)
    Account.create(:url => newUrl, :name => newUrl)
    redirect to("/#{newUrl}")
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => url)
    return false if @account.nil?
    @account.update(:name => URI.escape(params[:editname]))
  end

  get "/:url" do |url|
    @account = Account.first(:url => url)
    redirect to('/') if @account.nil?
    haml :index, :layout_engine => :erb
  end
end
