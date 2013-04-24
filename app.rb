require 'bundler/setup'
Bundler.require(:default)

require "sinatra/cookies"
require 'securerandom'

Dir.glob(File.join("{lib,models,controllers,routes}", "*.rb")).each{|f| require File.realpath(f)}

class App < Sinatra::Base
  register Sinatra::Partial
  helpers Sinatra::Cookies

  configure do
    set :haml, :format => :html5
    enable :partial_underscores
    enable :sessions
    set :session_secret, "43fb3pwgb3gb3"
    set(:cookie_options) do
      { :expires => Time.now + 3600*24*90, :expire_after => 2592000 }
    end
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.finalize

  configure :development, :test do
    # enable :logging, :dump_errors, :raise_errors
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/development.sqlite3")
    DataMapper.auto_upgrade!
  end

  configure :production do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/production.sqlite3")
    DataMapper.auto_upgrade!
    disable :run, :reload
  end

  before do
    cookies[:text] ||= "1"
    @text = getText(cookies[:text])
  end

  get "/" do
    createAccount() if cookies[:account].nil? || cookies[:account].empty?
    redirect to("/#{cookies[:account]}")
  end

  get "/:url/logout" do
    cookies[:account] = nil
    redirect to("/")
  end

  get "/texts.json" do
    content_type :json
    text = getText(cookies[:text].to_s)
    cookies[:text] = text["id"]
    text.to_json
  end

  post "/:url/up" do |url|
    @account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => 1)
    vote.account = @account
    vote.save
  end

  post "/:url/down" do |url|
    @account = Account.first(:url => URI.escape(url))
    vote = Vote.new(:vote => -1)
    vote.account = @account
    vote.save
  end

  get "/:url/graph.json" do |url|
    content_type :json
    account = Account.first(:url => URI.escape(url))
    limit = ((URI.escape(params[:width]).to_i-125)/10).ceil
    data = Hash.new
    data["tristateGraph"] = tristateGraphData(account, limit)
    data["pieChartWeek"] = pieChartData(account, 0, 8)
    data["pieChartYesterday"] = pieChartData(account, 0, 2)
    data["pieChartToday"] = pieChartData(account, nil, 1)
    data.to_json
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:name => URI.escape(params[:editname]))
  end

  get "/:url" do |url|
    @account = Account.first(:url => URI.escape(url))
    cookies[:account] = URI.escape(url)
    @account = createAccount(url) if @account.nil?
    haml :index, :layout_engine => :erb
  end

private

  def getText(currentID = 1)
    json = File.read('./models/texts.json')
    texts = JSON.parse(json)
    begin
      text = texts.sample
    end while text["id"] == currentID.to_s
    return text
  end

  def createAccount(url=nil)
    url ||= PasswordGenerator.new.generate(8)
    cookies[:account] = url
    Account.create(:url => url, :name => url)
  end

  def tristateGraphData(account, limit)
    allvotes = Vote.all(  :account => account,
                          :order => [ :created_at.desc ],
                          :limit => limit)
    votes = Array.new
    allvotes.each do |vote|
      votes << vote.vote
    end
    votes
  end

  def pieChartData(account, from, to)
    if from.nil?
      positive = Vote.all(:account => account, :created_at.gte => Date.today-to ).count(:vote => 1)
      negative = Vote.all(:account => account, :created_at.gte => Date.today-to ).count(:vote => -1)
    else
      positive = Vote.all(:account => account,
                          :created_at.lte => Date.today-from,
                          :created_at.gte => Date.today-to ).count(:vote => 1)
      negative = Vote.all(:account => account,
                          :created_at.lte => Date.today-from,
                          :created_at.gte => Date.today-to ).count(:vote => -1)
    end
    votes = Array.new()
    votes << positive << negative
    votes = [1,0] if (positive == 0 && negative == 0)
    votes
  end
end
