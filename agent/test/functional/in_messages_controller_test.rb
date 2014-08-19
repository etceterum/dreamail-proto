require 'test_helper'

class InMessagesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => InMessage.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    InMessage.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    InMessage.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to in_message_url(assigns(:in_message))
  end
  
  def test_edit
    get :edit, :id => InMessage.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    InMessage.any_instance.stubs(:valid?).returns(false)
    put :update, :id => InMessage.first
    assert_template 'edit'
  end
  
  def test_update_valid
    InMessage.any_instance.stubs(:valid?).returns(true)
    put :update, :id => InMessage.first
    assert_redirected_to in_message_url(assigns(:in_message))
  end
  
  def test_destroy
    in_message = InMessage.first
    delete :destroy, :id => in_message
    assert_redirected_to in_messages_url
    assert !InMessage.exists?(in_message.id)
  end
end
