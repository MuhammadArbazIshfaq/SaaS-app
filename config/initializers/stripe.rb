require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET_KEY']

Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY']
}
