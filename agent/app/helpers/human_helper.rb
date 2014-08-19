module HumanHelper
  ##########
  
  TOOLBAR_BUTTONS = {
    :new_message =>   { :icon => :mail_new, :id => 'button-message-new', :title => 'New Message', :url => { :controller => :out_messages, :action => :new } },
    :send_message =>  { :icon => :mail_send, :id => 'button-message-send', :title => 'Send' },
    :save_message =>  { :icon => :file_save, :id => 'button-message-save', :title => 'Save As Draft' },
    :edit_message =>  { :icon => :edit, :id => 'button-message-edit', :title => 'Edit Message', :disabled => true },
    :new_contact =>   { :icon => :contact_new, :id => 'button-contact-new', :title => 'Add Contact', :not_impl => true },
    :preferences =>   { :icon => :preferences, :id => 'button-preferences', :title => 'Preferences', :not_impl => true },
  }
  
  ##########
  
  def nav_link_to(name, options = {})
    display = name
    url = options[:url]
    
    if badge_id = options[:badge]
      display = "#{name}#{badge badge_id}"
    end
    
    html_options = {}
    html_options[:class] = 'current' if nav_current?(url)
    
    link_to display, url_for(url), html_options
  end
  
  def nav_current?(url)
    return false unless url.is_a?(Hash) && url[:controller] && url[:action]
    controller.controller_name == url[:controller].to_s && controller.action_name == url[:action].to_s
  end
  
  def format_time(t)
    return 'nil' unless t && t.is_a?(Time)
    
    t.strftime('%Y-%m-%d %H:%M')
  end
  
  def badge(id)
    "<span id='#{id}' class='badge inactive'>&nbsp;</span>"
  end
  
  ##########

  def nav_toolbar(*button_names)
    @content_for_nav_buttons = render_buttons([*button_names])
  end
  
  def no_nav_toolbar
    @content_for_nav_buttons = ''
  end
  
  def content_toolbar(*button_names)
    @content_for_content_buttons = render_buttons([*button_names])
  end
  
  def no_content_toolbar
    @content_for_content_buttons = ''
  end
  
  def other_toolbar(*button_names)
    @content_for_other_buttons = render_buttons([*button_names])
  end
  
  def no_other_toolbar
    @content_for_other_buttons = ''
  end
  
  ##########

  def no_global_title
    @content_for_no_global_title = true
  end

  ##########
  private
  
  def render_buttons(button_names)
    result = []
    (button_names || []).each do |button_name|
      button = TOOLBAR_BUTTONS[button_name]
      options = {}
      options[:title] = button[:title] if button[:title]
      options[:id] = button[:id] if button[:id]
      classes = []
      classes << 'disabled' if button[:disabled]
      classes << 'not-impl' if button[:not_impl]
      options[:class] = classes.join(' ') unless classes.empty?
      button_content = link_to(image_tag("/images/icons/#{button[:icon]}.png"), button[:url] || {}, options)
      result << button_content
    end
    result.join('')
  end
  
  ##########
end

