require 'rails_helper'

RSpec.describe "DelayedJobs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/delayed_jobs/index"
      expect(response).to have_http_status(:success)
    end
  end

end
