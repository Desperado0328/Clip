require 'test_helper'

class RssControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
	assert assigns(:xml).include?('<rss')
  end

  test "should load youtube.com" do
  	get :index
  	assert assigns(:youtube).xpath("//html").to_s.include?('YouTube')
  end

end
