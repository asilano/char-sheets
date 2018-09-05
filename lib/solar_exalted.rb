require_relative './exalted'

class Solar < Exalted
  stat :caste, :string, one_of: %w[
    Dawn
    Zenith
    Twilight
    Night
    Eclipse
  ]
end