class MassServiceSystem
  include MassService

  attr_accessor :log, :created_requests, :created_requests, :processed_requests, :unprocessed_requests, :rejected_requests, :queue_lengths

  def initialize(pipes_probabilities, queue_size)
    @pipes = pipes_probabilities.map { |failure_probability| MassService::Pipe.new(failure_probability) }
    @queue = MassService::Queue.new queue_size
    @rejected_requests = []
    @processed_requests = []
    @unprocessed_requests = []
    @created_requests = 0
    reset_time

    @queue_lengths = []
  end

  def perform
    execute_pipes
    finish_processing if finished?
    execute_queue
    execute_transfer if ready_for_second_pipe?
    ready_for_first_pipe? ? new_request : next_time
    self
  end

  def run(steps)
    states = steps.times.reduce([self.to_s]) { |a, _| a << perform.to_s }
    @unprocessed_requests = @pipes.map { |pipe| pipe.pull if pipe.request_state == :ready }
    states
  end

  def to_s
    "#{@queue.to_s}#{@time}#{@pipes.first}#{@pipes.second}"
  end

  private

  def reset_time
    @time = 2
  end

  def block
    @time = 0
  end

  def blocked?
    @time == 0
  end

  def next_time
    @time = 1
  end

  def execute_transfer
    transfer_request if ready_for_second_pipe?
    @queue_lengths << @queue.occupancy
  end

  def finish_processing
    @processed_requests << @pipes.second.pull
  end

  def transfer_request
    request = @pipes.first.pull

    if @pipes.second.vacant?
      @pipes.second.push request
    elsif !@queue.full?
      @queue.push request
    else
      reject_request request
    end
  end

  def reject_request(request)
    @rejected_requests << request
  end

  def new_request
    return block unless @pipes.first.vacant?
    new_request = MassService::Request.new
    @pipes.first.push new_request
    @created_requests += 1
    reset_time
  end

  def ready_for_first_pipe?
    @time < 2
  end

  def ready_for_second_pipe?
    @pipes.first.request_state == :processed
  end

  def finished?
    @pipes.second.request_state == :processed
  end

  def execute_pipes
    @pipes.each { |pipe| pipe.execute if pipe.request_state == :ready }
  end

  def execute_queue
    return if @queue.empty?
    @pipes.second.push @queue.pull if @pipes.second.vacant?
    @queue.handle_age
  end
end
