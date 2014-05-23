namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    admin = User.create!(name: "Alex Zami",
                 email: "zamihos@uth.gr",
                 password: "%mi5432",
                 password_confirmation: "%mi5432",
                 admin: true)
  end
end