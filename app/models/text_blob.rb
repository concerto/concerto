require_relative "content"

class TextBlob < ApplicationRecord
    include ContentType

    enum render_as: [ :plaintext, :html ]
end
