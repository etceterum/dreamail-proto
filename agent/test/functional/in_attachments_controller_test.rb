require 'test_helper'

class InAttachmentsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => InAttachment.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    InAttachment.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    InAttachment.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to in_attachment_url(assigns(:in_attachment))
  end
  
  def test_edit
    get :edit, :id => InAttachment.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    InAttachment.any_instance.stubs(:valid?).returns(false)
    put :update, :id => InAttachment.first
    assert_template 'edit'
  end
  
  def test_update_valid
    InAttachment.any_instance.stubs(:valid?).returns(true)
    put :update, :id => InAttachment.first
    assert_redirected_to in_attachment_url(assigns(:in_attachment))
  end
  
  def test_destroy
    in_attachment = InAttachment.first
    delete :destroy, :id => in_attachment
    assert_redirected_to in_attachments_url
    assert !InAttachment.exists?(in_attachment.id)
  end
end
