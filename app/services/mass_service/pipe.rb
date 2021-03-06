module MassService
  class Pipe
    attr_reader :state, :request_state, :request

    STATES = {
      vacant: '0',
      reserved: '1'
    }

    def initialize(failure_probability)
      @success_probability = 1.0 - failure_probability
      @state = :vacant
      @request_state = :none
    end

    def push(request)
      raise "Can't push, full" unless vacant?

      @request = request
      @state = :reserved
      @request_state = :ready
    end

    def pull
      raise "Can't pull, empty" if vacant?

      @state = :vacant
      @request_state = :none
      pulled_request = @request
      @request = nil
      pulled_request
    end

    def execute
      raise "Can't execute, empty" if vacant?

      @request_state = :processed if perform
    end

    def to_s
      STATES[@state]
    end

    def vacant?
      @state == :vacant
    end

    def reserved?
      @state == :reserved
    end

    def perform
      rand < @success_probability
    end
  end
end
