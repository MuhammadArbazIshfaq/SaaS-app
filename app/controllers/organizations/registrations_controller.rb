class Organizations::RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_tenant
  
  def new
    @user = User.new
    @plans = Plan.where(name: ['Free', 'Premium']).order(:price)
  end

  def create
    @user = User.new(sign_up_params)
    @plans = Plan.where(name: ['Free', 'Premium']).order(:price)
    
    # Debug logging
    Rails.logger.debug "Sign up params: #{sign_up_params}"
    Rails.logger.debug "All params: #{params.inspect}"
    
    begin
      ActsAsTenant.without_tenant do
        ActiveRecord::Base.transaction do
          # Create the organization first
          @organization = create_organization!
          Rails.logger.debug "Organization created: #{@organization.inspect}"
          
          # Handle payment for Premium plan
          if @organization.plan.name == 'Premium' && params[:payment_method_id].present?
            process_premium_payment!(@organization)
          end
          
          # Set user as admin and assign to organization
          @user.role = 'admin'
          @user.organization = @organization
          
          Rails.logger.debug "User before save: #{@user.inspect}"
          Rails.logger.debug "User valid? #{@user.valid?}"
          Rails.logger.debug "User errors: #{@user.errors.full_messages}" unless @user.valid?
          
          # Save the user
          if @user.save
            # Sign in the user
            sign_in(@user)
            
            # Send confirmation email if confirmable is enabled
            @user.send_confirmation_instructions if @user.respond_to?(:send_confirmation_instructions)
            
            success_message = @organization.plan.name == 'Premium' ? 
              'Welcome! Your organization has been created and your Premium subscription is active.' :
              'Welcome! Your organization has been created successfully.'
            
            redirect_to root_path, notice: success_message
          else
            # If user save fails, raise error to rollback transaction
            raise ActiveRecord::RecordInvalid.new(@user)
          end
        end
      end
    rescue Stripe::StripeError => e
      flash.now[:alert] = "Payment error: #{e.message}"
      render :new
    rescue ActiveRecord::RecordInvalid => e
      # Handle validation errors
      flash.now[:alert] = 'There was a problem creating your account. Please check the errors below.'
      
      # Add specific error details for debugging
      if e.record.is_a?(User)
        Rails.logger.error "User validation errors: #{@user.errors.full_messages}"
      elsif e.record.is_a?(Organization)
        Rails.logger.error "Organization validation errors: #{@organization&.errors&.full_messages}"
      end
      
      render :new
    rescue StandardError => e
      # Handle any other errors
      flash.now[:alert] = "Something went wrong: #{e.message}"
      Rails.logger.error "Organization registration error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render :new
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def create_organization!
    # Get the selected plan
    plan_choice = params[:plan_id] || 'free'
    selected_plan = case plan_choice.to_s
    when /premium/i, '3' # Plan ID 3 is Premium
      Plan.find_by!(name: 'Premium')
    else
      Plan.find_by!(name: 'Free')
    end

    # Get organization name and subdomain
    org_name = params[:organization_name].to_s.strip
    subdomain_input = params[:organization_subdomain].to_s.strip
    
    # Validate required fields
    raise StandardError, "Organization name is required" if org_name.blank?
    
    subdomain = subdomain_input.present? ? subdomain_input : generate_subdomain(org_name)
    
    Rails.logger.debug "Creating organization with name: '#{org_name}', subdomain: '#{subdomain}', plan: #{selected_plan.name}"

    # Create the organization
    organization = Organization.new(
      name: org_name,
      subdomain: subdomain.downcase.strip,
      plan: selected_plan,
      status: selected_plan.name == 'Free' ? 'trial' : 'active',
      trial_ends_at: 14.days.from_now
    )
    
    Rails.logger.debug "Organization before save: #{organization.inspect}"
    Rails.logger.debug "Organization valid? #{organization.valid?}"
    Rails.logger.debug "Organization errors: #{organization.errors.full_messages}" unless organization.valid?
    
    organization.save!
    organization
  end

  def generate_subdomain(org_name)
    # Generate subdomain from organization name
    base_subdomain = org_name.downcase
                            .gsub(/[^a-z0-9\s\-]/, '') # Remove special characters
                            .gsub(/\s+/, '-')          # Replace spaces with hyphens
                            .gsub(/-+/, '-')           # Replace multiple hyphens with single
                            .strip

    # Ensure uniqueness
    subdomain = base_subdomain
    counter = 1
    
    while Organization.exists?(subdomain: subdomain)
      subdomain = "#{base_subdomain}-#{counter}"
      counter += 1
    end

    subdomain
  end

  def process_premium_payment!(organization)
    payment_method_id = params[:payment_method_id]
    
    # Create or get existing product and price
    product = find_or_create_stripe_product
    price = find_or_create_stripe_price(product.id)
    
    # Create Stripe customer
    customer = Stripe::Customer.create({
      email: @user.email,
      name: organization.name,
      payment_method: payment_method_id,
      invoice_settings: {
        default_payment_method: payment_method_id,
      },
    })
    
    # Attach payment method to customer
    Stripe::PaymentMethod.attach(payment_method_id, {
      customer: customer.id,
    })
    
    # Create subscription with immediate payment attempt
    subscription = Stripe::Subscription.create({
      customer: customer.id,
      items: [{ price: price.id }],
      default_payment_method: payment_method_id,
      expand: ['latest_invoice'],
    })
    
    # Update organization with Stripe IDs
    organization.update!(
      stripe_customer_id: customer.id,
      stripe_subscription_id: subscription.id,
      status: 'active'
    )
    
    # Log subscription creation
    Rails.logger.info "Premium subscription created for organization #{organization.id} with status: #{subscription.status}"
    
    # If subscription is not active, log for investigation but don't fail
    unless subscription.status == 'active'
      Rails.logger.warn "Subscription status is #{subscription.status}, expected 'active' for #{subscription.id}"
    end
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
end
