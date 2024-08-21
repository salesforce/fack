require "rails_helper"

RSpec.describe AssistantsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/assistants").to route_to("assistants#index")
    end

    it "routes to #new" do
      expect(get: "/assistants/new").to route_to("assistants#new")
    end

    it "routes to #show" do
      expect(get: "/assistants/1").to route_to("assistants#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/assistants/1/edit").to route_to("assistants#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/assistants").to route_to("assistants#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/assistants/1").to route_to("assistants#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/assistants/1").to route_to("assistants#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/assistants/1").to route_to("assistants#destroy", id: "1")
    end
  end
end
