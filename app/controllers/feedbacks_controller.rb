
class FeedbacksController < ApplicationController

  def new
    @feedback = Feedback.new
    @feedback.grade = params[:feedback] ? params[:feedback][:grade] || 0 : 0
    @feedback.comment = params[:comment]
    @task_id = params[:task_id]
    @task_id ||= params[:id]
  end

  def create
    @task_id = params[:task_id]
    @task_id ||= params[:id]
    p = params["feedback"]
    @feedback ||= Feedback.new
    @feedback.comment ||= p['comment']
    @feedback.grade ||= p['grade']
    @feedback.user_id ||= current_user.id
    @feedback.task_id ||= params[:task_id]
    if @feedback.save
      #render :new
      redirect_back_or current_user
    else
      flash[:alert] = "Maximum comment length = 250 characters"
      render :new
    end
  end



  def destroy
    
  end

end
