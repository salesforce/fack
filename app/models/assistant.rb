class Assistant < ApplicationRecord
  serialize :libraries, type: Array
end
