module ApplicationHelper
  def organization_status_badge(organization)
    return '' unless organization
    
    case organization.status
    when 'trial'
      content_tag :span, 'Trial', class: 'badge bg-warning text-dark'
    when 'active'
      content_tag :span, 'Active', class: 'badge bg-success'
    when 'suspended'
      content_tag :span, 'Suspended', class: 'badge bg-danger'
    when 'cancelled'
      content_tag :span, 'Cancelled', class: 'badge bg-secondary'
    else
      content_tag :span, 'Unknown', class: 'badge bg-light text-dark'
    end
  end
  
  def plan_badge(plan)
    return content_tag(:span, 'No Plan', class: 'badge bg-secondary') unless plan
    
    css_class = case plan.name.downcase
                when /free/
                  'badge bg-secondary'
                when /basic/
                  'badge bg-primary'
                when /premium/
                  'badge bg-warning text-dark'
                when /enterprise/
                  'badge bg-danger'
                else
                  'badge bg-info text-dark'
                end
    
    content_tag :span, "#{plan.name} ($#{plan.price}/#{plan.billing_cycle})", class: css_class
  end
  
  def trial_warning(organization)
    return '' unless organization&.trial?
    
    days_left = organization.days_left_in_trial
    
    if days_left <= 0
      content_tag :div, class: 'alert alert-danger' do
        "⚠️ Your trial has expired! Please upgrade your plan to continue using the service."
      end
    elsif days_left <= 3
      content_tag :div, class: 'alert alert-warning' do
        "⏰ Your trial expires in #{days_left} day#{'s' if days_left != 1}. Upgrade now to avoid service interruption."
      end
    end
  end
  
  def user_usage_percentage(organization)
    return 0 unless organization&.plan&.max_users
    
    current_users = organization.users.count
    max_users = organization.plan.max_users
    
    (current_users.to_f / max_users * 100).round(1)
  end
end
