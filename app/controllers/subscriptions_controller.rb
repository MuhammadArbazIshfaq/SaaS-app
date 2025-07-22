class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:webhook]
  before_action :require_admin, except: [:webhook]
  
  # Skip CSRF protection for webhook endpoint
  skip_before_action :verify_authenticity_token, only: [:webhook]
  
  def show
    @current_plan = current_organization.plan
    @premium_plan = Plan.find_by(name: 'Premium')
  end
  
  def create
    payment_method_id = params[:payment_method_id]
    premium_plan = Plan.find_by(name: 'Premium')
    
    begin
      # Create or get existing product
      product = find_or_create_stripe_product
      
      # Create or get existing price
      price = find_or_create_stripe_price(product.id)
      
      # Create customer
      customer = Stripe::Customer.create({
        email: current_user.email,
        name: current_organization.name,
        payment_method: payment_method_id,
        invoice_settings: {
          default_payment_method: payment_method_id,
        },
      })
      
      # Attach payment method to customer
      Stripe::PaymentMethod.attach(payment_method_id, {
        customer: customer.id,
      })
      
      # Create subscription
      subscription = Stripe::Subscription.create({
        customer: customer.id,
        items: [{ price: price.id }],
        payment_behavior: 'default_incomplete',
        payment_settings: {
          save_default_payment_method: 'on_subscription'
        },
        expand: ['latest_invoice.payment_intent'],
      })
      
      # Update organization with Stripe IDs and plan
      current_organization.update!(
        plan: premium_plan,
        stripe_customer_id: customer.id,
        stripe_subscription_id: subscription.id
      )
      
      # Handle the subscription status
      case subscription.status
      when 'incomplete'
        # Payment requires confirmation
        if subscription.latest_invoice&.payment_intent
          render json: {
            client_secret: subscription.latest_invoice.payment_intent.client_secret,
            subscription_id: subscription.id
          }
        else
          render json: { error: 'Payment setup incomplete' }, status: 422
        end
      when 'active'
        # Payment successful immediately
        render json: { success: true }
      else
        render json: { error: "Subscription status: #{subscription.status}" }, status: 422
      end
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Error: #{e.message}"
      render json: { error: e.message }, status: 422
    rescue => e
      Rails.logger.error "Unexpected Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: 500
    end
  end
  
  def success
    flash[:notice] = "Subscription successful! Your organization has been upgraded to Premium."
    redirect_to dashboard_path
  end
  
  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    
    # Skip signature verification if no webhook secret is configured (development only)
    if endpoint_secret.present? && endpoint_secret != 'whsec_your_webhook_secret_here'
      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError
        render json: { error: 'Invalid payload' }, status: 400
        return
      rescue Stripe::SignatureVerificationError
        render json: { error: 'Invalid signature' }, status: 400
        return
      end
    else
      # For development: parse payload directly without signature verification
      begin
        event = JSON.parse(payload)
      rescue JSON::ParserError
        render json: { error: 'Invalid payload' }, status: 400
        return
      end
    end
    
    case event['type']
    when 'invoice.payment_succeeded'
      handle_successful_payment(event['data']['object'])
    when 'customer.subscription.deleted'
      handle_subscription_cancellation(event['data']['object'])
    end
    
    render json: { status: 'success' }
  end
  
  private
  
  def require_admin
    redirect_to dashboard_path unless current_user.admin?
  end
  
  def find_or_create_stripe_product
    # Try to find existing product
    products = Stripe::Product.list(limit: 100)
    existing_product = products.data.find { |p| p.name == 'Premium Plan' }
    
    return existing_product if existing_product
    
    # Create new product if it doesn't exist
    Stripe::Product.create({
      name: 'Premium Plan',
      description: 'Unlimited projects for your organization'
    })
  end
  
  def find_or_create_stripe_price(product_id)
    # Try to find existing price for this product
    prices = Stripe::Price.list(product: product_id, limit: 100)
    existing_price = prices.data.find do |p| 
      p.unit_amount == 2999 && 
      p.currency == 'usd' && 
      p.recurring&.interval == 'month'
    end
    
    return existing_price if existing_price
    
    # Create new price if it doesn't exist
    Stripe::Price.create({
      unit_amount: 2999, # $29.99
      currency: 'usd',
      recurring: { interval: 'month' },
      product: product_id
    })
  end
  
  def handle_successful_payment(invoice)
    subscription_id = invoice['subscription']
    organization = Organization.find_by(stripe_subscription_id: subscription_id)
    return unless organization
    
    premium_plan = Plan.find_by(name: 'Premium')
    organization.update!(plan: premium_plan) unless organization.plan == premium_plan
    
    Rails.logger.info "Payment successful for organization #{organization.id}"
  rescue => e
    Rails.logger.error "Failed to process successful payment: #{e.message}"
  end
  
  def handle_subscription_cancellation(subscription)
    organization = Organization.find_by(stripe_subscription_id: subscription['id'])
    return unless organization
    
    free_plan = Plan.find_by(name: 'Free')
    organization.update!(
      plan: free_plan,
      stripe_subscription_id: nil
    )
    
    Rails.logger.info "Organization #{organization.id} downgraded to Free plan"
  rescue => e
    Rails.logger.error "Failed to downgrade organization: #{e.message}"
  end
end
