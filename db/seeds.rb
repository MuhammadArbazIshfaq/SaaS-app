# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create subscription plans for project management app
Plan.find_or_create_by!(name: 'Free') do |plan|
  plan.price = 0.00
  plan.billing_cycle = 'monthly'
  plan.max_users = 10 # Unlimited team members in free plan
  plan.features = "1 Project\nUnlimited team members\nBasic project management\nEmail support\nFile uploads"
  plan.active = true
end

Plan.find_or_create_by!(name: 'Premium') do |plan|
  plan.price = 29.99
  plan.billing_cycle = 'monthly'
  plan.max_users = 1000 # Virtually unlimited
  plan.features = "Unlimited Projects\nUnlimited team members\nAdvanced project management\nPriority support\nFile uploads\nAdvanced analytics\nCustom integrations\nProject templates"
  plan.active = true
end

puts "✅ Created #{Plan.count} subscription plans for project management"
