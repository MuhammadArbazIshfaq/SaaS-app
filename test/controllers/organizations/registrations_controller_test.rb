require "test_helper"

class Organizations::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get organizations_registrations_new_url
    assert_response :success
  end

  test "should get create" do
    get organizations_registrations_create_url
    assert_response :success
  end
end
