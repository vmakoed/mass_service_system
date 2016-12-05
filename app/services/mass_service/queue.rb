module MassService
  class Queue
    attr_reader :occupancy

    def initialize(size)
      @size = size
      @occupancy = 0
    end

    def push
      raise "Can't push, full" if full?
      @occupancy += 1
    end

    def pull
      raise "Empty, can't pull" if empty?
      @occupancy -= 1
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
  end
end