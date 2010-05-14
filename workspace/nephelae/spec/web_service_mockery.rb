require 'mongrel'

module Mock
  
  module WebServiceMockery
    
    ##
    # Example for mocking service at '/my/service' with method POST:
    #   @server = mock_service :post => '/my/service' do |head, body|
    #     head['Content-type'] = "text/plain"
    #     body.write("content ...")
    #   end
    #
    #   # call the service ...
    #
    #   @server.graceful_shutdown
    #
    # The service mock may receive a different URI for each HTTP method (eg. <tt>:put => '/other', :delete => '/some'</tt>)
    def mock_service(options, &behavior)
      port = options[:port].to_s
      server = Mongrel::HttpServer.new("0.0.0.0", port)
      
      [:get, :post, :put, :delete, :header, :options, :trace].each do |method|
        server.register options[method], ServiceMockHandler.new(method, behavior) if options[method]
      end
      
      server.run
      wait_server_start
      server
    end
    
    private
    def wait_server_start
      sleep 0.1
    end
    
  end
  
  class ServiceMockHandler < Mongrel::HttpHandler
    
    def initialize(method, behavior)
      @method = method.to_s.downcase.to_sym
      @behavior = behavior
    end
    
    def process(request, response)
      (method_not_supported_for request, response; return) unless @method == method_of(request)
      response.start(200) do |head, out|
        @behavior.call(head, out)
      end
    end
    
    private
    def method_of(request)
      request.params[Mongrel::Const::REQUEST_METHOD].downcase.to_sym
    end
    
    def method_not_supported_for(request, response)
      response.start 501 do |head, out|
        out.write "#{method_of(request)} isn't being mocked."
      end
    end

  end

end
