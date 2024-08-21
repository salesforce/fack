require "rails_helper"

RSpec.describe MessagesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/messages").to route_to("messages#index")
    end

    it "routes to #new" do
      expect(get: "/messages/new").to route_to("messages#new")
    end

    it "routes to #show" do
      expect(get: "/messages/1").to route_to("messages#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/messages/1/edit").to route_to("messages#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/messages").to route_to("messages#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/messages/1").to route_to("messages#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/messages/1").to route_to("messages#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/messages/1").to route_to("messages#destroy", id: "1")
    end
  end
end
