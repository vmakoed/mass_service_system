class MassServiceSystem
  include MassService

  attr_accessor :states

  def initialize(pipes_probabilities, queue_size)
    @pipes = pipes_probabilities.map { |failure_probability| MassService::Pipe.new(failure_probability) }
    @queue = MassService::Queue.new queue_size
    @requests = { rejected: [], processed: [], unprocessed: [] }
    @queue_lengths = []
    @states = []
  end

  def run(steps)
    reset_time
    record_state
    steps.times { perform }
    pull_processed_request if finished?
    pull_unprocessed_requests
    results steps
  end

  private

  def perform
    record_queue_stats unless @queue.empty?
    execute_pipes
    pull_processed_request if finished?
    execute_queue
    execute_transfer if ready_for_second_pipe?
    ready_for_first_pipe? ? new_request : next_time
    record_state
  end

  def results(steps)
    requests = @requests.values.flatten

    {
      state_probabilities: state_probabilities,
      relative_bandwidth: @requests[:processed].length * 1.0 / requests.length,
      average_queue_length: (@queue_lengths.reduce(&:+) || 0) * 1.0 / steps,
      average_request_age: @requests[:processed].map(&:age).reduce(&:+) * 1.0 / @requests[:processed].length
    }
  end

  def state_probabilities
    @states.uniq.reduce({}) { |a, e| a.merge({ e => state_probability(e) }) }
  end

  def state_probability(state)
    @states.select { |test_state| test_state == state}.length * 1.0 / @states.length
  end

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
  end

  def pull_processed_request
    @requests[:processed] << @pipes.second.pull
  end

  def pull_unprocessed_requests
    @requests[:unprocessed] += @pipes.select { |pipe| pipe.request_state == :ready }.map(&:pull)
  end

  def transfer_request
    return @pipes.second.push @pipes.first.pull if @pipes.second.vacant?
    return @queue.push @pipes.first.pull unless @queue.full?
    reject_request @pipes.first.pull
  end

  def reject_request(request)
    @requests[:rejected] << request
  end

  def new_request
    return block unless @pipes.first.vacant?

    new_request = MassService::Request.new
    @pipes.first.push new_request
    reset_time
  end

  def record_state
    @states << state
  end

  def state
    "#{@queue.to_s}#{@time}#{@pipes.first}#{@pipes.second}"
  end

  def ready_for_first_pipe?
    @time != 2
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
  end

  def record_queue_stats
    @queue_lengths << @queue.occupancy
    @queue.handle_age
  end
end
