require 'test_helper'

class OutMessagesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => OutMessage.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    OutMessage.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    OutMessage.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to out_message_url(assigns(:out_message))
  end
  
  def test_edit
    get :edit, :id => OutMessage.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    OutMessage.any_instance.stubs(:valid?).returns(false)
    put :update, :id => OutMessage.first
    assert_template 'edit'
  end
  
  def test_update_valid
    OutMessage.any_instance.stubs(:valid?).returns(true)
    put :update, :id => OutMessage.first
    assert_redirected_to out_message_url(assigns(:out_message))
  end
  
  def test_destroy
    out_message = OutMessage.first
    delete :destroy, :id => out_message
    assert_redirected_to out_messages_url
    assert !OutMessage.exists?(out_message.id)
  end
end
