class Hash
  def check_missing_keys(reference)
    result = []
    reference.each do |key, value|
      if self[key].nil?
        result << key
      else
        if value.respond_to?(:check_missing_keys) && self[key].respond_to?(:check_missing_keys)
          inner_result = self[key].check_missing_keys(value)
          result << {key => inner_result} unless inner_result.empty?
        end
      end
    end
    result.sort {|x,y| x.to_s <=> y.to_s}
  end
end
