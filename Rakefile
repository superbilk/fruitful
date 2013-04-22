
namespace :db do

  desc "Deletes all etries in database"
  task :reset => :environment do
    puts "votes#: #{Vote.count}"
    puts "accounts#: #{Account.count}"
    puts "Deleting..."
    DataMapper.auto_migrate!
    puts "votes#: #{Vote.count}"
    puts "accounts#: #{Account.count}"
  end

  desc "Recereates database"
  task :reset_hard => :environment do
    puts "Resetting..."
    DataMapper.auto_migrate!
    puts "votes#: #{Vote.count}"
    puts "accounts#: #{Account.count}"
  end

end

task :environment do
  root = ::File.dirname(__FILE__)
  require ::File.join( root, 'app' )
end
