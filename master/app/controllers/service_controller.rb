require 'openssl'

class ServiceController < ApplicationController
  include Socketry
  
  # skip_before_filter :verify_authenticity_token

  before_filter :begin_socketry
  
  attr_reader   :user, :node, :input, :output
  
  def render_with_socketry(*args)
    # logger.error "end_socketry BEGIN"
    
    cipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).encrypt
    cipher.key = @cipher_key
    cipher.iv = @cipher_iv
    
    @output[Proto::NOW_FIELD] ||= Time.now
    
    data = Encoder.encode(@output)
    data = cipher.update(data)
    data << cipher.final

    render_without_socketry :text => data, :status => 200
    # logger.error "end_socketry END"
  end
  
  alias_method_chain :render, :socketry
  
  rescue_from 'Unchanged' do |e|
    render_without_socketry :text => e, :status => 304
  end

  rescue_from 'BadRequest' do |e|
    
    # FIXME
    logger.error e.backtrace.join("\n")
    
    render_without_socketry :text => e, :status => 400
  end

  rescue_from 'BadIdentity' do |e|
    render_without_socketry :text => e, :status => 401
  end
  
  protected
  
  def timestamp_output(t)
    @output[Proto::NOW_FIELD] = t
  end
  
  protected
  
  def bad_request
    raise BadRequest.new('Bad Request')
  end
  
  def bad_identity
    raise BadIdentity.new('Bad Identity')
  end
  
  def unchanged
    raise Unchanged.new('Unchanged')
  end
  
  protected
  
  def ensure_existing_user
    bad_request if user.new_record?
  end
  
  def ensure_existing_node
    bad_request if node.new_record?
  end
  
  private
  
  def begin_socketry
    # logger.info "begin_socketry BEGIN"
    # logger.info "Time: #{Time.now}"
    
    head = params[Proto::HEAD_FIELD]
    body = params[Proto::BODY_FIELD]
    bad_request unless head && body
    
    # deal with the head: check/initialize cipher key, cipher iv; check protocol signature
    private_key = Config::master.private_key
    begin
      head = private_key.private_decrypt(head)
      head = Encoder.decode(head)
    rescue Object => e
      
      #FIXME
      puts e.backtrace.join("\n")
      exit
      
      bad_request
    end
    decipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).decrypt
    bad_request unless head.is_a?(Array) && head.size == 3
    decipher.key = @cipher_key = head.shift
    bad_request unless @cipher_key.is_a?(String) && @cipher_key.length == decipher.key_len
    decipher.iv = @cipher_iv = head.shift
    bad_request unless @cipher_iv.is_a?(String) && @cipher_iv.length == decipher.block_size
    proto_signature = head.shift
    bad_request unless proto_signature == Proto.signature
    
    # deal with the body: decrypt using cipher key/iv, check that the body is a Hash
    begin
      body = decipher.update(body)
      body << decipher.final
      body = Encoder.decode(body)
    rescue Object => e
      # logger.error e.backtrace.join("\n")
      bad_request
    end
    
    bad_request unless body.is_a?(Hash)
    
    # find or initialize new user
    login = body[Proto::User::LOGIN_FIELD]
    password = body[Proto::User::PASSWORD_FIELD]
    bad_request unless login && password
    @user = User.find_by_login(login)
    if @user
      bad_identity unless @user.password_correct?(password)
    else
      @user = User.new(:login => login, :password => password)
    end
    
    # find or initialize node
    node_uid = body[Proto::Node::UID_FIELD]
    if node_uid
      @node = @user.nodes.find_by_uid(node_uid) or bad_identity
    else
      @node = @user.new_record? ? Node.new : @user.nodes.build
    end
    
    @input = body
    @output = {}
    
    # logger.info "begin_socketry END"
  end
  
end
