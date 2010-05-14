module Mock
  module XenAPIMockery
  
    def mock_session
      SessionMock.new
    end
  
    def success_response
      {'Status' => 'Success', 'Value' => ''}
    end
  
    class SessionMock
      def initialize
        @mocks = {}
      end
    
      def method_missing(name, *args)
        unless @mocks.has_key?(name)
          @mocks[name] = mock
          self.stub!(name).and_return @mocks[name]
        end
      
        @mocks[name]
      end
    
      def mock
        obj = Object.new

        def obj.copy
        end
        
        obj
      end
    end

  end
end
