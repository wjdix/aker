When /^I go to the login form$/ do
  visit '/login'
end

When /^(?:when )?I enter username "([^\"]*)" and password "([^\"]*)"$/ do |username, password|
  fill_in 'username', :with => username
  fill_in 'password', :with => password
  click_button 'Log in'
end

Then /^I should be sent to the login page$/ do
  if @using_rack_test
    follow_redirect!
    doc = Nokogiri.HTML(last_response.body)
    (doc/'input[name="username"]').should_not be_empty
    (doc/'input[name="password"]').should_not be_empty
  else
    page.should have_field('username')
    page.should have_field('password')
  end
end

Then /^I should see "([^\"]*)" in the "([^\"]*)" field$/ do |text, field|
  page.should have_field(field, :with => text)
end
