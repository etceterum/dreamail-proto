class TestController < ApplicationController
  def render_with_socketry
    logger.warn "HERE"
    render_without_socketry :text => 'ok'
  end

  alias_method_chain :render, :socketry
  
  around_filter do |controller, action|
    logger.warn "BEFORE"
    action.call
    logger.warn "AFTER"
  end
  
  def new
    logger.warn "INSIDE"
  end
  
end
