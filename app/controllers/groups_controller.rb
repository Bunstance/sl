class GroupsController < ApplicationController
  include ApplicationHelper
  helper_method :sort_column, :sort_direction
  before_filter :author_user, only: [:show, :index, :edit, :update, :destroy, :new, :create]
  # GET /groups
  # GET /groups.json
  def index
    @groups = Group.all
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @show_resets = params[:resets] == 'true' ? true : false
    @group = Group.find(params[:id])    
    if @group and params[:notice_text]
      @group.update_attribute(:notice, params[:notice_text])
    end
    if @group and params[:get_feedback]
      @group.update_attribute(:feedback_due, 1.minute.ago)
    end
    @members = User.order(:surname).select {|u| u.group == @group.name}
    @tasks = @group.task_list
    @tasks ||= []
    @tasks.reverse!
    @recent = true if params[:recent] == 'true'
    @tasks = @tasks.first(3) if @recent
    @tasks = @tasks.paginate(params[:page]||1,15)
    @n_tasks = @tasks.count
    @scores = Hash.new {{}}
    @feedback = {}
    @lastcomment = {}
    @lastgrade = {}
    @members.each do |user|
      lastfeedback = Feedback.last_by(user.id)
      if lastfeedback
        @lastgrade[user.id] = lastfeedback.grade
        @lastcomment[user.id] = lastfeedback.comment
      end
      task_ids = user.task_list.map {|x| x.id.to_i}
      feedback = Feedback.where(:user_id => user.id).all
      @feedback[user.id] = Hash[task_ids.map {|x| [x,feedback.find {|y| y.task_id.to_s == x.to_s}]}]

      scores = Hash[user.task_scores.map {|x| [x[0], x[1..-1]]}]
      @scores[user.id] = Hash[task_ids.map {|y| [y, scores[y] ? (scores[y][0] == true ? ['100', scores[y][1]] : ["#{(scores[y][2] * 100)/Task.find(y).question_count}", scores[y][1]]) : ['--', 0]]} ]
    end


    
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end

  def assign



    @groups = Group.all
    @teachers = User.where(author: true).to_a
    @n_staff = @teachers.count
    if params[:assign]
      @owns = {}
      @groups.each do |group|
        s = []
        @n_staff.times do |i|
          ar = params["#{i}_owns".to_sym]
          if ar and ar.include?(group.id.to_s)
            @owns[[@teachers[i],group.id]] == true
            s << @teachers[i].id
          end
        end
        group.update_attribute(:teacher, s.join(punc1))
      end
    end





    @owns = {}
    @groups.each do |g|
      teachers = g.teacher
      teachers ||= ''
      teachers = teachers.split(punc1)
      teachers.each do |t|
        @owns[[g.id,t]] = true
      end
    end


  end


  
 private

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
  end

  def sort_column
    Item.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end

  def author_user
    if current_user
      redirect_to(root_path) unless current_user.author
    else
      redirect_to(signin_path)
    end
  end

end
