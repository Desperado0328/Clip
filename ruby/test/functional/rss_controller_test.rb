require 'test_helper'

class RssControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
	assert assigns(:xml).include?('<rss')
  end

end
