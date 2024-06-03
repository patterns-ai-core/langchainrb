require "webmock"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    record_on_error: false,
    match_requests_on: %i[method uri body]
  }

  # config.filter_sensitive_data("<OPENAI KEY>") { IdentityClient.configs.fetch(:default).host }
end

RSpec.configure do |config|
  config.around(:each) do |example|
    vcr = example.metadata[:vcr]
    vcr_cassette_name = vcr[:cassette_name] if vcr.is_a?(Hash)
    vcr_cassette_name ||= example.full_description

    if vcr.nil?
      WebMock.disable!
      VCR.turned_off { example.run }
      WebMock.enable!
    else
      VCR.insert_cassette vcr_cassette_name
      example.run
      VCR.eject_cassette vcr_cassette_name
    end
  end
end
