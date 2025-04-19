# frozen_string_literal: true

class DelayedJobsController < ApplicationController
  before_action :set_job, only: [:destroy]

  def index
    @priority_filter = params[:priority]

    @jobs = case @priority_filter
            when 'high'
              Delayed::Job.where('priority < ?', 5)
            when 'low'
              Delayed::Job.where('priority >= ?', 5)
            else
              Delayed::Job.all
            end

    @jobs = @jobs.order(priority: :asc, run_at: :desc)
    @total_jobs_count = @jobs.count
    @jobs = @jobs.page(params[:page])
  end

  def run_now
    @job = Delayed::Job.find(params[:id])

    authorize @job, :update?

    @job.update(run_at: Time.now)
    redirect_to delayed_jobs_path, notice: 'Job has been scheduled to run immediately.'
  end

  def destroy
    authorize @job

    if @job.destroy
      flash[:notice] = 'Job was successfully deleted.'
    else
      flash[:alert] = 'Job could not be deleted.'
    end
    redirect_to delayed_jobs_path
  end

  private

  def set_job
    @job = Delayed::Job.find(params[:id])
  end
end
