module MassService
  class Queue
    attr_reader :occupancy, :requests

    def initialize(size)
      @size = size
      @occupancy = 0
      @requests = []
    end

    def push(request)
      raise "Can't push, full" if full?
      requests << request
      request.increase_age
      @occupancy += 1
    end

    def pull
      raise "Empty, can't pull" if empty?
      pulled_request = @requests.first

      @requests -= [pulled_request]
      @occupancy -= 1
      pulled_request
    end

    def empty?
      @occupancy == 0
    end

    def to_s
      @occupancy
    end

    def full?
      @occupancy == @size
    end

    def handle_age
      @requests.each(&:increase_age)
    end
  end
end