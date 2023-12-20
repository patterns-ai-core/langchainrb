module CustomMatchers
  # Validates that the array is of certain size
  # @param size [Integer] Array size/length
  def array_with_strings_matcher(size:)
    proc do |array|
      array.is_a?(Array) &&
        array.length == size &&
        array.all? { |e| e.is_a?(String) }
    end
  end
end
