require 'rails_helper'

RSpec.describe LibrariesController, type: :controller do
  let(:valid_attributes) { { name: 'My Library' } }
  let(:user) { User.create!(email: "vijay@gmail.com", password: "Password1!") }

  before do
    allow_any_instance_of(BaseLibrariesController).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Library" do
        expect {
          post :create, params: { library: valid_attributes }
        }.to change(Library, :count).by(1)
      end
    end

    # other tests...
  end
end
