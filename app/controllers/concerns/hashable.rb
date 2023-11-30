module Hashable
  extend ActiveSupport::Concern

  def calculate_sha(text, algorithm = 'sha256')
    # Create a digest object based on the specified algorithm
    digest = Digest.const_get(algorithm.upcase).new

    # Update the digest with the text string's content
    digest.update(text)

    # Get the hexadecimal representation of the checksum
    digest.hexdigest
  end
end
