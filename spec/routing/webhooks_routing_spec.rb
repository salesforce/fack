require "rails_helper"

RSpec.describe WebhooksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/webhooks").to route_to("webhooks#index")
    end

    it "routes to #new" do
      expect(get: "/webhooks/new").to route_to("webhooks#new")
    end

    it "routes to #show" do
      expect(get: "/webhooks/1").to route_to("webhooks#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/webhooks/1/edit").to route_to("webhooks#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/webhooks").to route_to("webhooks#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/webhooks/1").to route_to("webhooks#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/webhooks/1").to route_to("webhooks#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/webhooks/1").to route_to("webhooks#destroy", id: "1")
    end
  end
end
