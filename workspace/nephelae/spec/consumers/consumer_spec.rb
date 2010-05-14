require File.dirname(__FILE__) + '/../spec_helper'

describe Consumer do
  class FakeConsumer < Consumer
    attr_accessor :test_result
    queue 'Fake'
    callback do |queue_message|
      self.test_result = "action #{queue_message[:action]} executed"
    end
  end

  context "class" do
    it "should have a queue method" do
      Consumer.should respond_to(:queue)
    end

    it "should have a callback method" do
      Consumer.should respond_to(:callback)
    end

    context "when publishing messages to a consumer queue" do
      before :each do
        @mocked_stomp = mock(:stomp)
        @mocked_stomp.should_receive(:close)
        Stomp::Client.should_receive(:new).with(NephelaeConfig[:broker].merge(:max_reconnect_attempts => 1)).and_return @mocked_stomp
      end

      it "should be able to pass a hash as parameter" do
        message = {:param => :param_value}
        @mocked_stomp.should_receive(:publish).with(FakeConsumer.queue_name, message.to_yaml, {:persistent => true, :suppress_content_length=>true})
        FakeConsumer.publish(message)
      end
      
      it "should accept a parameterless call" do
        @mocked_stomp.should_receive(:publish).with(FakeConsumer.queue_name, {}.to_yaml, {:persistent => true, :suppress_content_length=>true})
        FakeConsumer.publish
      end
    end

    context "when exclusive is" do
      it "set to true, it should add the headers for exclusive queue consumer" do
        class FakeExclusiveConsumer < Consumer
          exclusive true
        end
        FakeExclusiveConsumer.headers[:'activemq.exclusive'].should be_true
      end
      
      it "set to false, it should not add the headers for exclusive queue consumer" do
        class FakeNonExclusiveConsumer < Consumer
          exclusive false
        end
        FakeNonExclusiveConsumer.headers[:'activemq.exclusive'].should be_false
      end
      
      it "not set, it should default to true" do
        class FakeDefaultConsumer < Consumer
        end
        FakeDefaultConsumer.headers[:'activemq.exclusive'].should be_false
      end
    end
  end

  context "instances" do
  	before(:each) do
      @consumer = FakeConsumer.new
    end

    it "should have a queue name" do
      @consumer.queue_name == '/queue/Fake'
    end

    it "should be able to instantiate a broker client" do
      Stomp::Client.stub(:new).and_return(:stubbed_broker)
      @consumer.send(:broker_client).should be(:stubbed_broker)
    end

    context "when subscribing the queue" do
      it "should raise an error if no queued process is assigned" do
        class IncompleteFakeConsumer < Consumer
        end
        consumer = IncompleteFakeConsumer.new
        client = mock(:client)
        lambda { consumer.start }.should raise_error(ArgumentError)
      end

      it "should subscribe the queue passing the block" do
        client = mock(:client)
        client.should_receive(:subscribe).with(@consumer.queue_name, Consumer::headers)
        @consumer.should_receive(:broker_client).and_return(client)
        @consumer.start
      end
    end

    context "when running the process" do
      context "and executing it successfully" do
        before(:each) do
          @message = mock(:message)
          @message.stub!(:body).and_return({:action => 'test'}.to_yaml)
          @message.stub!(:headers).and_return({:suppress_content_length => 'true'})

          client = mock(:client)
          client.should_receive(:acknowledge)
          @consumer.should_receive(:broker_client).and_return(client)
        end

        it "should parse the message with YAML" do
          @consumer.should_receive(:handle).with({:action => 'test', :headers => @message.headers})
          @consumer.send(:execute_process, @message)
        end

        it "should generate a log message" do
          logger = mock(:logger)
          logger.should_receive(:info)
          @consumer.should_receive(:logger).and_return(logger)
          @consumer.send(:execute_process, @message)
        end

        it "should return the processed message" do
          @consumer.send(:execute_process, @message)
          @consumer.test_result.should be('action test executed')
        end
      end

      context "and raising errors during its execution" do
        before :each do
          @message = mock(:message, :body => "", :headers => {'suppress_content_length' => 'true', 'retry_count' => '3'})
          @logger = mock(:logger, :info => '')
          @broker_client = mock(:broker_client)
          @consumer.stub!(:broker_client).and_return(@broker_client)
        end

        it "should log all exceptions" do
          @logger.should_receive(:error)
          @consumer.stub!(:logger).and_return(@logger)
          @broker_client.stub!(:unreceive)
          @consumer.send(:execute_process, @message)
        end

        it "should send the processed message to the end of the queue" do
          @broker_client.should_receive(:unreceive).with(@message, :max_redeliveries => 2)
          @consumer.send(:execute_process, @message)
        end
        
        it "should create a ProcessingError instance" do
          ProcessingError.should_receive(:create)
          @broker_client.stub!(:unreceive)
          @consumer.send(:execute_process, @message)
        end
      end
    end
    
  end
end
