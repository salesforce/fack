require "rails_helper"

RSpec.describe ChatsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/chats").to route_to("chats#index")
    end

    it "routes to #new" do
      expect(get: "/chats/new").to route_to("chats#new")
    end

    it "routes to #show" do
      expect(get: "/chats/1").to route_to("chats#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/chats/1/edit").to route_to("chats#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/chats").to route_to("chats#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/chats/1").to route_to("chats#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/chats/1").to route_to("chats#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/chats/1").to route_to("chats#destroy", id: "1")
    end
  end
end
