class DelayedJobsController < ApplicationController
  before_action :set_job, only: [:destroy]

  def index
    @jobs = Delayed::Job.all
  end

  def destroy
    authorize @job

    if @job.destroy
      flash[:notice] = "Job was successfully deleted."
    else
      flash[:alert] = "Job could not be deleted."
    end
    redirect_to delayed_jobs_path
  end

  private

  def set_job
    @job = Delayed::Job.find(params[:id])
  end
end
