class MassServiceSystem
  include MassService

  attr_accessor :log, :requests, :processed_requests, :queue_lengths

  def initialize(pipes_probabilities, queue_size)
    @pipes = pipes_probabilities.map { |failure_probability| MassService::Pipe.new(failure_probability) }
    @queue = MassService::Queue.new queue_size
    @requests = 0
    @rejected_requests = 0
    @processed_requests = 0
    reset_time
    @log = []
    @queue_lengths = []
  end

  def perform
    execute_pipes
    finish_processing if @pipes.second.request_state == :processed
    execute_queue
    execute_transfer if ready_for_second_pipe?
    return next_time unless ready_for_first_pipe?
    execute_processing
    self
  end

  def run(steps)
    steps.times.reduce([self.to_s]) { |a, _| a << perform.to_s }
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
    self
  end

  def execute_transfer
    transfer_request if ready_for_second_pipe?
    @queue_lengths << @queue.occupancy
  end

  def finish_processing
    @pipes.second.pull
    @processed_requests += 1
  end

  def transfer_request
    @pipes.first.pull

    if @pipes.second.vacant?
      @pipes.second.push
    elsif !@queue.full?
      @queue.push
    else
      reject_request
    end
  end

  def reject_request
    @rejected_requests += 1
  end

  def execute_processing
    return block unless @pipes.first.vacant?
    @requests += 1
    @pipes.first.push
    reset_time
  end

  def ready_for_first_pipe?
    @time < 2
  end

  def ready_for_second_pipe?
    @pipes.first.request_state == :processed
  end

  def execute_pipes
    @pipes.each { |pipe| pipe.execute if pipe.reserved? }
    record_log
  end

  def record_log
    @log << @pipes.each_with_index.map do |pipe, index|
      if pipe.request_state == :processed
        "1-q#{index + 1}"
      elsif pipe.request_state == :ready
        "q#{index + 1}"
      else
        ''
      end
    end
  end

  def execute_queue
    return if @queue.empty?

    if @pipes.second.vacant?
      @queue.pull
      @pipes.second.push
    end
  end
end
