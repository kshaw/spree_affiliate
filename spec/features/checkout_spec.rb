require 'spec_helper'

feature 'affiliate store credit feature' do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:payment_method) }
  let!(:zone) { create(:zone) }
  let!(:product) { create(:product, :name => "RoR Mug", :price => 49.99) }
  let(:sender) { create(:admin_user) }

  let!(:address) { create(:address, :state => Spree::State.first) }


  def add_product_to_cart_and_fill_address
    visit spree.product_path(product)

    click_button "Add To Cart"
    click_button "Checkout"

    str_addr = "bill_address"
    select "United States", :from => "order_#{str_addr}_attributes_country_id"
    ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
      fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
    end

    select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
    check "order_use_billing"
    click_button "Save and Continue"
    click_button "Save and Continue"
  end

  scenario "recipient credit on register", :js => true do
    reset_affiliate_preferences do |config|
      config.recipient_credit_on_register_amount = 30
    end

    visit "/?ref_id=#{sender.ref_id}"
    visit "/signup"

    fill_in "Email", :with => "paul@gmail.com"
    fill_in "Password", :with => "mypassword"
    fill_in "Password Confirmation", :with => "mypassword"
    click_button "Create"
    add_product_to_cart_and_fill_address

    page.should have_content("You have $30.00 of store credits")
    fill_in "order_store_credit_amount", :with => "30"

    click_button "Save and Continue"
    page.should have_content("Your order has been processed successfully")
  end

  scenario "sender credit on order_paid", :js => true do
    reset_affiliate_preferences do |config|
      config.sender_credit_on_order_paid_amount = 10
    end

    visit "/?ref_id=#{sender.ref_id}"
    visit "/signup"

    fill_in "Email", :with => "paul@gmail.com"
    fill_in "Password", :with => "mypassword"
    fill_in "Password Confirmation", :with => "mypassword"
    click_button "Create"

    add_product_to_cart_and_fill_address

    page.should_not have_content("store credits")

    click_button "Save and Continue"
    page.should have_content("Your order has been processed successfully")
    click_link "Logout"

    sign_in_as! sender
    visit spree.admin_order_payments_path(order = Spree::User.find_by_email("paul@gmail.com").orders.first)

    click_icon :capture

    add_product_to_cart_and_fill_address
    page.should have_content("You have $10.00 of store credits")
    fill_in "order_store_credit_amount", :with => "10"
    click_button "Save and Continue"
    page.should have_content("Your order has been processed successfully")
  end

end