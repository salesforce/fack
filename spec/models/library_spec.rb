require 'rails_helper'

RSpec.describe Library, type: :model do
  it 'is invalid without a name' do
    library = build(:library, name: nil)
    expect(library).not_to be_valid
    expect(library.errors[:name]).to include("can't be blank")
  end
end
