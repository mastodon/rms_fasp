class StorageRequest < ApplicationRecord
  belongs_to :fasp_base_server, class_name: "FaspBase::Server"
  belongs_to :ap_object
  belongs_to :media_file, optional: true

  enum :state, [ :enqueued, :processing, :ok, :rejected ]

  validates :file_url, presence: true
  validates :rejection_reason, presence: { if: :rejected? }
end
