module Matcher
 
  module Global

    Spec::Matchers.define :be do |expected|
      match do |given|
        given == expected
      end
      failure_message_for_should do |given|
        "expected #{given.inspect} to be #{expected.inspect}"
      end
      failure_message_for_should_not do |given|
        "expected #{given.inspect} not to be #{expected.inspect}"
      end
      description do
        "checks equality"
      end
    end

    Spec::Matchers.define :include_error_message_for do |target, expected_message, options|
      match do |given|
        specific_scope = :"activerecord.errors.models.#{given.class.name.underscore}.attributes.#{target}.#{expected_message}"
        fallback_scope = :"activerecord.errors.models.#{given.class.name.underscore}.#{expected_message}", :"activerecord.errors.messages.#{expected_message}"

        options = (options || {}).merge(:default => fallback_scope, :raise => true)
        @error_message = I18n.t(specific_scope, options)
        given.valid?
        [given.errors.on(target)].flatten.compact.include? @error_message
      end
      failure_message_for_should do |given|
        "expected #{target} - #{given.errors.on(target)} to include \"#{@error_message}\""
      end
      failure_message_for_should_not do |given|
        "expected #{target} not to include \"#{@error_message}\""
      end
      description do
        "checks if a given object includes the localized error message"
      end
    end
  end

end
