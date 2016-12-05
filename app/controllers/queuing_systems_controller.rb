class QueuingSystemsController < ApplicationController
  before_action :setup_steps_number, only: :show

  FAILURE_PROBABILITIES = [0.4, 0.5]

  def edit
  end

  def show
    @queuing_system = MassServiceSystem.new(FAILURE_PROBABILITIES, 2)
    @states = [@queuing_system.to_s]
    run_queuing_system
  end

  private

  def run_queuing_system
    @states = @queuing_system.run @steps_number
    # state_probabilities

    @relative_bandwidth = @queuing_system.processed_requests.length * 1.0 / @queuing_system.created_requests
    # @average_queue_length = @queuing_system.queue_lengths.reduce(&:+) * 1.0 / @steps_number
    # requests =  @queuing_system.processed_requests + @queuing_system.unprocessed_requests
    # p requests
    # queue_requests = requests.compact.select { |e| e.age != 0 }
    # @average_request_age = queue_requests.reduce(0) { |a, e| a += e.age } * 1.0 / queue_requests.length
  end

  def state_probabilities
    p @states.uniq.map { |state| p "p#{state} = #{state_probability(state)}" }
  end

  def state_probability(state)
    @states.select { |test_state| test_state == state}.length * 1.0 / @states.length
  end

  def setup_steps_number
    @steps_number = params[:steps_number].to_i
  end
end
