require_relative './exalted'

class Solar < Exalted
  stat :caste, :string, one_of: %w[
    Dawn
    Zenith
    Twilight
    Night
    Eclipse
  ]
  stat :supernal_ability, :string, one_of: Exalted::ALL_ABILITIES

end