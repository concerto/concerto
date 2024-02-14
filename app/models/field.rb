class Field < ApplicationRecord
    serialize :alt_names, coder: JSON, type: Array
end
