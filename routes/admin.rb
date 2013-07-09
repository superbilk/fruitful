# encoding: UTF-8

class Admin < Sinatra::Base
  get "/:adminurl/raw.json" do |adminurl|
    account = Account.first(:adminurl => URI.escape(adminurl))
    data = account.votes.all
    json data
  end

  get "/:adminurl/raw.csv" do |adminurl|
    account = Account.first(:adminurl => URI.escape(adminurl))
    data = account.votes.all
    content_type 'application/octet-stream'
    attachment "fruitful_#{account.url}_#{Time.now.to_i}.csv"
    csv_string = CSV.generate do |csv|
      data.each do |row|
        csv << [row.id, row.created_at.strftime("%F"), row.created_at.strftime("%R"), row.vote]
      end
    end
  end

end
