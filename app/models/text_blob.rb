class TextBlob < ApplicationRecord
    has_one :content, as: :subtype

    accepts_nested_attributes_for :content

    enum render_as: [ :plaintext, :html ]
end
