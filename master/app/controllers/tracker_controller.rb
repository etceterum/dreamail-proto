class TrackerController < ServiceController
  ##########

  before_filter :ensure_existing_user
  before_filter :ensure_existing_node

  ##########
end
