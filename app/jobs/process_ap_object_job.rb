class ProcessApObjectJob < ApplicationJob
  PUBLIC_URIS = %w[https://www.w3.org/ns/activitystreams#Public as:Public Public].freeze

  def perform(ap_object)
    @ap_object = ap_object

    if @ap_object.public? || public_object_with_media?
      accept_storage_requests_if_plausible
    else
      reject_storage_requests!("Object is not a valid ActivityPub object or not public")
    end
  rescue HTTPX::HTTPError => e
    if e.status.in?(400...500)
      reject_storage_requests!("Object cannot be fetched")
    else
      raise e
    end
  end

  private

  def public_object_with_media?
    return false if @ap_object.public == false

    object_json = FaspBase::ActivityPubObject.new(uri: @ap_object.uri).fetch

    if actor?(object_json)
      @ap_object.update!(
        public: true,
        media_urls: [ object_json["icon"], object_json["image"] ].compact
      )
      true
    elsif publicly_addressed_object?(object_json)
      media_urls = extract_media_urls(object_json)
      @ap_object.update!(public: true, media_urls:)
      true
    else
      @ap_object.update!(public: false)
      false
    end
  end

  def actor?(json)
    json["inbox"] && json["outbox"]
  end

  def publicly_addressed_object?(json)
    (json.values_at("to", "cc").flatten & PUBLIC_URIS).any?
  end

  def extract_media_urls(json)
    [ json["attachment"] ].flatten.filter_map do |attachment|
      next unless attachment["url"] && attachment["mediaType"]

      attachment["url"]
    end
  end

  def accept_storage_requests_if_plausible
    @ap_object.storage_requests.enqueued.each do |storage_request|
      if @ap_object.media_urls.include?(storage_request.file_url)
        ProcessStorageRequestJob.perform_later(storage_request)
      else
        storage_request.reject!("File is not included in ActivityPub object")
      end
    end
  end

  def reject_storage_requests!(message)
    @ap_object.storage_requests.enqueued.each do |storage_request|
      storage_request.reject!(message)
    end
  end
end
