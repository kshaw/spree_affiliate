Spree::CheckoutController.class_eval do
  include AffiliateCredits

  private

  def after_complete
    session[:order_id] = nil

    if spree_current_user && spree_current_user.affiliate_partner && current_user.orders.where(:state => 'complete').count == 1
      sender = spree_current_user.affiliate_partner.partner

      #create credit (if required)
      create_affiliate_credits(sender, spree_current_user, "purchase")
    end
  end
end
