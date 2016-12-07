module MassService
  class Request
    attr_reader :age

    def initialize
      @age = 0
    end

    def increase_queue_age
      @age += 1
    end
  end
end
