module ImgProxyUrlConcern
  extend ActiveSupport::Concern

  def verify_signature_parameter
    url = Addressable::URI.parse(request.url)
    raise FaspBase::Error unless url.query_values && url.query_values["sig"]

    encoded_sig = url.query_values["sig"]
    sig = Base64.decode64(encoded_sig)
    # editing query_values with addressable returns sorted query parameters
    # upper case letters come before lower case letters
    # like "https://www.example.com/query?X=1&Y=2&a=3%b=4"
    url.query_values = url.query_values.except("sig")
    url_string = url.display_uri.to_s

    public_pem = server.public_key_pem
    public_key = OpenSSL::PKey.read(public_pem)
    digest = Digest::SHA256.base64digest(url_string)
    raise FaspBase::Error unless public_key.verify(nil, sig, digest)

    true
  end

  def build_img_proxy_url
    storage = StorageRequest.find_by(media_file_id: params[:id])
    raise ActiveRecord::RecordNotFound unless storage && storage.state == "ok"

    file_url = storage.media_file.s3_url
    raise FaspBase::Error unless file_url
    path = build_path_with_signature(file_url)
    raise FaspBase::Error unless file_url

    # http://imgproxy.example.com/%signature/%processing_options/%encoded_source_url.%extension
    url = "#{ENV.fetch("IMGPROXY_ENDPOINT")}#{path}"
  end

  private

  def server
    return unless request.params["namespace"].present?

    FaspBase::Server.find_by(namespace: request.params["namespace"])
  end


  def build_path_with_signature(file_url)
    salt = ENV.fetch("IMGPROXY_SALT")
    key = ENV.fetch("IMGPROXY_KEY")
    raise FaspBase::Error unless salt && key

    @encoded_source_url = Base64.urlsafe_encode64(file_url).tr("=", "")
    variants = options_segment
    path = "#{variants}/#{@encoded_source_url}.#{request.params[:ext]}"
    # prepend salt to path and calc hmac encode 64 like
    # <salt>/rs:fill:300:400:0/g:sm/aHR0cDovL2V4YW1w/bGUuY29tL2ltYWdl/cy9jdXJpb3NpdHku/anBn.png
    digest = OpenSSL::Digest.new("sha256")
    hmac = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(digest, key, "#{salt}#{path}")).tr("=", "")

    signed_path = "/#{hmac}#{path}"
  end

  def options_segment
    # this only works, when with only one processing Option
    variants = request.params[:any]
    return "" unless variants

    colon_separated = variants.gsub!("/", ":")
    "/#{colon_separated}"
  end
end
