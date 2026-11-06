module FaspBase::ServerExtensions
  extend ActiveSupport::Concern

  prepended do
    before_save :set_namespace
  end

  private

  def set_namespace
    return if base_url.blank? || !base_url_changed?

    url = Addressable::URI.parse(base_url)
    self.namespace = url.host.gsub(".", "-").downcase
    self.namespace << "-#{url.port}" if url.port
  end
end
