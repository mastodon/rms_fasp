require "test_helper"

class ProcessApObjectJobTest < ActiveJob::TestCase
  setup do
    @job = ProcessApObjectJob.new
  end

  test "when object is public it enqueues processing jobs for all open storage requests" do
    ap_object = ap_objects(:public)

    assert_enqueued_jobs 2, only: ProcessStorageRequestJob do
      @job.perform(ap_object)
    end
  end

  test "it rejects requests for files not in ActivityPub object" do
    ap_object = ap_objects(:public)
    storage_request = storage_requests(:enqueued_public_wrong_file)

    @job.perform(ap_object)

    assert storage_request.reload.rejected?
  end

  test "when object is private it does not enqueue any job and rejects requests" do
    ap_object = ap_objects(:private)
    enqueued_storage_requests = ap_object.storage_requests.enqueued.to_a

    assert_no_enqueued_jobs do
      @job.perform(ap_object)
    end

    enqueued_storage_requests.each do |storage_request|
      assert storage_request.reload.rejected?
    end
  end

  test "when an actor's visibility is not yet known it fetches the object, persists media urls and queues job" do
    ap_object = ap_objects(:unknown)

    stub_ap_object_request(ap_object.uri, :actor)

    assert_enqueued_jobs 1, only: ProcessStorageRequestJob do
      @job.perform(ap_object)
    end

    assert_equal [ "https://fedi.example.com/attachments/1.png" ], ap_object.media_urls
  end

  test "when a post's visibility is not yet known it fetches the object, persists media urls and queues job" do
    ap_object = ap_objects(:unknown)

    stub_ap_object_request(ap_object.uri, :public_post)

    assert_enqueued_jobs 1, only: ProcessStorageRequestJob do
      @job.perform(ap_object)
    end

    assert_equal [ "https://fedi.example.com/attachments/1.png" ], ap_object.media_urls
  end

  test "when a non-public post's visibility is not yet known it fetches the object and rejects the request" do
    ap_object = ap_objects(:unknown)
    stub_ap_object_request(ap_object.uri, :private_post)

    assert_no_enqueued_jobs do
      @job.perform(ap_object)
    end

    assert storage_requests(:enqueued_unknown_object).rejected?
  end

  test "when fetching an object fails with a client error the request is rejected" do
    ap_object = ap_objects(:unknown)
    storage_request = storage_requests(:enqueued_unknown_object)

    [ 401, 403, 404, 410 ].each do |code|
      storage_request.update!(state: :enqueued)
      stub_failed_request(ap_object.uri, code)

      assert_no_enqueued_jobs do
        @job.perform(ap_object)
      end

      assert storage_request.reload.rejected?
    end
  end

  test "when fetching an object fails with a server error an exception is raised" do
    ap_object = ap_objects(:unknown)
    [ 500, 502, 503, 504 ].each do |code|
      stub_failed_request(ap_object.uri, code)

      assert_raises HTTPX::Error do
        @job.perform(ap_object)
      end
    end
  end

  private

  def stub_ap_object_request(uri, method)
    headers = { "content-type" => "application/activity+json" }

    stub_request(:get, uri)
      .to_return_json(body: send(method, uri), headers:)
  end

  def stub_failed_request(uri, code)
    stub_request(:get, uri)
      .to_return(status: code)
  end

  def actor(id)
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      id:,
      type: "Person",
      inbox: "#{id}/inbox",
      outbox: "#{id}/outbox",
      icon: "https://fedi.example.com/attachments/1.png"
    }
  end

  def public_post(id)
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      id:,
      type: "Note",
      to: "https://www.w3.org/ns/activitystreams#Public",
      content: "test",
      attachment: {
        type: "Document",
        mediaType: "image/png",
        url: "https://fedi.example.com/attachments/1.png"
      }
    }
  end

  def private_post(id)
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      id:,
      type: "Note",
      to: "https://other.example.com/actor/23",
      content: "test",
      attachment: {
        type: "Document",
        mediaType: "image/png",
        url: "https://fedi.example.com/attachments/1.png"
      }
    }
  end
end
