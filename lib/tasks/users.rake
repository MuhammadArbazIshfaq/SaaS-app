namespace :users do
  desc "Confirm all unconfirmed invited users"
  task confirm_invited: :environment do
    # Find users that are unconfirmed and belong to an organization (invited users)
    unconfirmed_users = User.where(confirmed_at: nil).where.not(organization_id: nil)
    
    puts "Found #{unconfirmed_users.count} unconfirmed invited users"
    
    unconfirmed_users.each do |user|
      user.skip_confirmation!
      user.save!
      puts "Confirmed user: #{user.email}"
    end
    
    puts "Done! All invited users are now confirmed."
  end
end
