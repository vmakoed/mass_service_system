class MassServiceSystemsController < ApplicationController
  def index
  end

  def show
    @failure_probabilities = [params.fetch(:failure_first).to_f, params.fetch(:failure_second).to_f]
    @steps_number = params.fetch :steps_number
    @results = MassServiceSystem.new(@failure_probabilities, 2).run params[:steps_number].to_i
  end
end
