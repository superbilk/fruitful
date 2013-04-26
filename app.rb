# encoding: UTF-8
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
    cookies[:language] ||= "en"
    @text = getText(cookies[:text], cookies[:language])
  end

  get "/" do
    createAccount() if cookies[:account].nil? || cookies[:account].empty?
    redirect to("/#{cookies[:account]}")
  end

  get "/:url/logout" do
    cookies.clear
    redirect to("/")
  end

  get "/:adminurl/raw.json" do |adminurl|
    account = Account.first(:adminurl => URI.escape(adminurl))
    raw = account.votes.all()
    raw.to_json
  end

  get "/texts.json" do
    content_type :json
    text = getText(cookies[:text], cookies[:language])
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
    limit = ((URI.escape(params[:width]).to_i-155)/10).ceil
    data = Hash.new
    data["tristateGraph"] = tristateGraphData(account, limit)
    data["pieChartMonth"] = pieChartData(account, 30)
    data["pieChartWeek"] = pieChartData(account, 7)
    data["pieChartYesterday"] = pieChartData(account, 1)
    data["pieChartToday"] = pieChartData(account)
    data.to_json
  end

  post "/:url/edit" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:name => URI.escape(params[:editname]))
  end

  post "/:url/language" do |url|
    @account = Account.first(:url => URI.escape(url))
    @account.update(:language => URI.escape(params[:language]))
    cookies[:language] = URI.escape(params[:language])
  end

  get "/:url" do |url|
    @account = Account.first(:url => URI.escape(url))
    cookies[:account] = URI.escape(url)
    cookies[:language] = @account.language
    @account = createAccount(url) if @account.nil?
    haml :index, :layout_engine => :erb
  end

private

  def getText(currentID = 0, lang = "en")
    file = File.open('./models/texts.json', "r:UTF-8")
    texts = JSON.parse(file.read)
    begin
      text = texts[lang].sample
    end while text["id"] == currentID.to_s
    return text
  end

  def createAccount(url=nil)
    cookies.clear
    url ||= PasswordGenerator.new.generate(8)
    cookies[:account] = url
    Account.create(:url => url, :name => url)
  end

  def tristateGraphData(account, limit)
    allvotes = Vote.all(  :account => account,
                          :order => [ :created_at.desc ],
                          :created_at.gte => Date.today,
                          :limit => limit)
    votes = Array.new
    allvotes.each do |vote|
      votes << vote.vote
    end
    votes
  end

  def pieChartData(account, daysBefore=0)
    if daysBefore==0 # today
      positive = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote.gte => 1)
      negative = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote.lte => -1)
      zero     = Vote.all(:account => account, :created_at.gte => Date.today ).count(:vote => 0)
    else
      positive = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote.gte => 1)
      negative = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote.lte => -1)
      zero     = Vote.all(:account => account,
                          :created_at.lt => Date.today,
                          :created_at.gte => Date.today-(daysBefore) ).count(:vote => 0)
    end
    votes = Array.new()
    votes << positive << negative << zero
    votes = [0,0,1] if (positive == 0 && negative == 0 && zero == 0)
    votes
  end
end
