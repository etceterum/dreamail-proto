class UserController < ServiceController
  ##########
  
  def new
    unchanged unless user.new_record?
    user.save or bad_request
  end
  
  ##########
end
