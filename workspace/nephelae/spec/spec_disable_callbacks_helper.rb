module ActiveRecord
  class Base
    def self.without_callbacks(*callbacks)
      # Get all callback chains and then find the related callback method
      @original_callbacks ||= {}
      callback_chains = methods.select {|method_name| method_name =~ /_callback_chain$/ }
      callback_chains = callback_chains.map{|method_name| method_name.gsub(/_callback_chain$/, '') }

      # Save all original callbacks
      callback_chains.each do |callback_chain|
        chain = self.send(callback_chain)
        @original_callbacks[callback_chain] = chain.clone

        # Remove all callbacks if no parameters are given
        if callbacks.empty?
          chain.clear
        # Remove only the given parameters
        else
          chain.delete_if {|callback| callbacks.include?(callback.method) }
        end
      end

      # Executes the block code
      result = block_given? ? yield : nil

      # Reset all callbacks to the original state
      callback_chains.each do |callback_chain|
        chain = self.send(callback_chain)
        chain.clear
        @original_callbacks[callback_chain].each do |callback|
          chain << callback
        end
      end

      result
    end
  end  
end
