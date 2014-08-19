class ServiceController < ApplicationController
  include Socketry
  
  before_filter :begin_socketry

  attr_reader :input, :output, :client_uid, :client_public_key

  def render_with_socketry(*args)
    # logger.error "end_socketry BEGIN"
    
    cipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).encrypt
    cipher.key = cipher_key = cipher.random_key
    cipher.iv = cipher_iv = cipher.random_iv

    begin
      head = @client_public_key.public_encrypt(Encoder.encode([cipher_key, cipher_iv, Proto::signature]))
    rescue
      bad_request
    end
    
    @output[Proto::NOW_FIELD] ||= Time.now
    
    data = Encoder.encode(@output)
    data = cipher.update(data)
    data << cipher.final

    render_without_socketry :text => (head + data), :status => 200
    # logger.error "end_socketry END"
  end
  
  alias_method_chain :render, :socketry

  rescue_from 'BadRequest' do |e|
    # logger.error e.backtrace.join("\n")
    render_without_socketry :text => e, :status => 400
  end

  rescue_from 'BadIdentity' do |e|
    render_without_socketry :text => e, :status => 401
  end

  rescue_from 'NotFound' do |e|
    render_without_socketry :text => e, :status => 404
  end

  protected
  
  def bad_request
    raise BadRequest.new('Bad Request')
  end
  
  def bad_identity
    raise BadIdentity.new('Bad Identity')
  end
  
  def not_found
    raise NotFound.new('Bad Identity')
  end

  private
  
  def begin_socketry
    # logger.info "begin_socketry BEGIN"
    
    head = params[Proto::HEAD_FIELD]
    body = params[Proto::BODY_FIELD]
    bad_request unless head && body
    
    # deal with the head: check/initialize cipher key, cipher iv; check protocol signature
    private_key = Config::node.private_key
    begin
      head = private_key.private_decrypt(head)
      head = Encoder.decode(head)
    rescue Object => e
      puts e.backtrace.join("\n")
      bad_request
    end
    decipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).decrypt
    bad_request unless head.is_a?(Array) && head.size == 3
    decipher.key = decipher_key = head.shift
    bad_request unless decipher_key.is_a?(String) && decipher_key.length == decipher.key_len
    decipher.iv = decipher_iv = head.shift
    bad_request unless decipher_iv.is_a?(String) && decipher_iv.length == decipher.block_size
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
    
    # this node's UID must be present in the request
    my_uid = body[Proto::Node::OTHER_UID_FIELD]
    bad_request unless my_uid && my_uid == Config.node.uid

    # client node UID and public key must be present in the request
    @client_uid = body[Proto::Node::UID_FIELD]
    bad_identity unless @client_uid && @client_uid.is_a?(String)
    client_public_key_data = body[Proto::Node::PUBLIC_KEY_FIELD]
    bad_identity unless client_public_key_data && client_public_key_data.is_a?(Hash)
    client_modulus = client_public_key_data[Proto::Node::MODULUS_FIELD]
    client_exponent = client_public_key_data[Proto::Node::EXPONENT_FIELD]
    bad_identity unless client_modulus && client_exponent
    begin
      @client_public_key = OpenSSL::PKey::RSA.new
      e = OpenSSL::BN.new(client_exponent.to_s)
      @client_public_key.e = e
      n = OpenSSL::BN.new(client_modulus, 2)
      @client_public_key.n = n
    rescue Object => e
      bad_identity
    end
    
    @input = body
    @output = {}
    
    # logger.info "begin_socketry END"
  end
  
end
