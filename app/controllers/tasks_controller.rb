class TasksController < ApplicationController
    helper_method :sort_column, :sort_direction, :author_user
    include ApplicationHelper

    before_filter :author_user, only: [:index, :edit, :update, :destroy, :new, :create]
    
    def max_tries
        3
    end
    
    def decode_string(string)
        array = string.split(punc1)
        array = array.map {|x| x.split(punc2, -1)}
    end
    
    def encode_string(array)
        array.map {|x| x.join(punc2) }.join(punc1)
    end
    
    def ans_array_insert(array, item)
        #1/0 unless item.count == 4
        id, i, j = item[0..2].map(&:to_i)
        pos = ans_index(array,id,i,j)
        @deletions ||= []
        @deletions << array[pos] if pos
        array.delete_at(pos) if pos
        array << item
        array.delete_at(0) if array.length > 25
    end

    def ans_lookup(array,id,i,j)
        pos = ans_index(array,id,i,j)
        pos ? array[pos][-1] : ""
    end
    
    def ans_index(array,id,i,j)
        array.index {|x| x[0..2].map(&:to_s) == [id,i,j].map(&:to_s) }
    end
    
    def update_task_data(all_task_data,task_data,datapos,user)
        task_data = task_data[0..1] if task_data[1] < 0
        if datapos
            all_task_data[datapos] = task_data
        else
            all_task_data << task_data
        end
        user.update_attribute(:task_data,encode_string(all_task_data))
        sign_in current_user
    end
    
    def show
        #session[:recent_answers] = nil
        revision_mode = params[:finished] ? true : false
        id = params[:id].to_i
        @task = Task.find(id)
        user = current_user
        recent_answer_string = session[:recent_answers]
        recent_answer_string ||= ''
        recent_answer_string = '' if params[:finished]
        recent_answers = decode_string(recent_answer_string)

        if params[:feedback_given]
            store_location
            redirect_to new_feedback_path(request.parameters)
        end

        question_attempted = params[:attempted]
        if question_attempted
            answers_given = params["ans#{question_attempted}".to_sym]
            m = answers_given.count
            m.times do |j|
                ans_array_insert(recent_answers,[id,question_attempted,j,answers_given[j]])
            end
        end

        group = user.group_object
        
        @feedback_due = group ? !(Feedback.date_of_last_by(user.id) > [feedback_interval.ago,group.feedback_due].max or Feedback.where(task_id:@task.id, user_id:user.id).first) : false
        
        session[:recent_answers] = encode_string(recent_answers)
        task_data_string = user.task_data || ""
        #task_data_string = ""
        
        all_task_data = decode_string(task_data_string)
        task_data = [id, 0] 
        datapos = all_task_data.index {|x| x[0].to_i == id}
        task_data = all_task_data[datapos].map(&:to_i) if datapos
        if revision_mode
            task_data = [id, -(task_data[1] + 1)]
            update_task_data(all_task_data,task_data,datapos,user)
        end
        @revision_mode = true if task_data[1] < 0
        #@data81 = task_data
        
        @answer = {}
        @given_answer = {}
        @text = {}
        @image = {}
        @video = {}
        @marksymbol = {}
        @progress_text = {}
        @top = {}
        @tail = {}
        @parts = {}
        @divstyle = Hash.new {''}
        thing_list = @task.content.split(' ')
        @n = thing_list.count
        #1/0 unless @n
        q = 0
        @n.times do |i|
            thing = thing_list[i]
            if thing[0] == "Q"
                task_data[q + 2] ||= 0
                task_data[q + 2] = -1 if task_data[1] < 0
                question_id = thing[1..-1]
                @question = Question.find(question_id)



                seed = @revision_mode ? 100 : task_data[q + 2]/max_tries + 1
                seed = (-task_data[q + 2] - 1)/max_tries + 1 if seed < 1
                
                seed += 40*i

                construct(seed)
                @text[i] = @example_question
                m = @example_answers.count
                @parts[i] = m
                prompts = @promptlist.map {|x| x.split('`')}
                score = []
                m.times do |j|
                    @top[[i,j]] = prompts[j][0]
                    @tail[[i,j]] = prompts[j][1]
                    @answer[[i,j]] = @example_answers[j][0..-3]
                    prec = @example_answers[j][-2..-1]
                    ans = ans_lookup(recent_answers,id,i,j)
                    score[j] = ans == "" ? -1 : match(ans,@answer[[i,j]],prec)
                    @given_answer[[i,j]] = ans
                end
                result = 2
                case score
                when [0]*m
                    result = 0
                when [-1]*m
                    result = -1
                end
                result = 1 if  score.max == 1 and score.min >= 0
                if @grouped_answers
                    @marksymbol[[i,m - 1]] = result
                else
                    m.times do |j|
                        @marksymbol[[i,j]] = score[j]
                        @marksymbol[[i,j]] = 2 if score[j] == -1 and result != -1
                    end
                end
                
                reset = false
                @finished = false
                if (question_attempted == i.to_s)
                    case result
                    when 1..2
                        @divstyle[i] = ' bad'
                    when 0
                        @divstyle[i] = ' good'
                    end
                    if (task_data[q + 2] > -1) and !@revision_mode
                        
                        case result
                        when 1..2
                            task_data[q + 2] += 1
                            if (task_data[q + 2] % max_tries) == 0
                              reset = true
                              task_data[1] += 1
                            end
                              
                        when 0
                            task_data[q + 2] = -1 - task_data[q + 2]
                        end
                        update_task_data(all_task_data,task_data,datapos,user)
                    end
                end 
                if reset
                    m.times do |j|
                        ans_array_insert(recent_answers,[id,question_attempted,j,''])
                    end
                    session[:recent_answers] = encode_string(recent_answers)
            
                    redirect_to task_path(:reset => "#{i}")
                end
                
                if @revision_mode
                    @progress_text[i] = ""
                elsif params[:reset] == i.to_s
                    @progress_text[i] = "You used all the attempts, so this question has been reset (#{task_data[q + 2] % max_tries} attempts)"
                elsif task_data[1] < 0 or (task_data[q + 2] and task_data[q + 2] < 0)
                    @progress_text[i] = "You have successfully answered this question"
                else
                    @progress_text[i] = "You have had #{task_data[q + 2] % max_tries} out of #{max_tries} attempts"
                end
                @task_data = task_data
                @all_task_data = all_task_data
                q += 1
            else
                element = Element.find(thing)
                @text[i] = element.safe_content if element.category == "text"
                @image[i] = element.safe_content if element.category == "image"
                @video[i] = element.safe_content if element.category == "video"
            end
        end
        
        if task_data[2] and task_data[2..-1].max <= -1 and !@revision_mode
            @finished = true
            @progress_text.each_key do |key|
                @progress_text[key] = "Congratulations, this page is complete. All questions will reset for revision mode."
            end
        end
        if current_user.author
            updated = params[:assign]
            groups_set = (params[:group_ids] || []) if updated
            @groups = Group.order('name asc')
            @set = {}
            @groups.each do |group|
                g_id = group.id
                task_string = group.tasks||''
                @set[g_id] = task_string.split(' ').include?(id.to_s)
                if updated and (@set[g_id] ^ groups_set.include?(g_id.to_s))
                    if @set[g_id]
                        array = task_string.split(' ')
                        array.delete(id.to_s)
                        task_string = array.join(' ')
                    else
                        task_string = task_string == '' ? id.to_s : task_string + ' ' + id.to_s 
                    end
                    @set[g_id] = !@set[g_id] 
                    group.update_attribute(:tasks, task_string)
                end
            end
        end
    end
    
    def index
        #params[:sort]||='id'
        #params[:direction]||='desc'
        #@tasks = Task.order(params[:sort] + ' ' + params[:direction]).paginate(per_page: number_per_page, page: params[:page])
        @tasks = Task.all
    end
    
    def destroy
        id = params[:id]
        task = Task.find(id)
        task.destroy
        groups = Group.all
        groups.each do |group|
            g_id = group.id
            task_string = group.tasks||''
            if task_string.split(' ').include?(id.to_s)
                array = task_string.split(' ')
                array.delete(id.to_s)
                task_string = array.join(' ')
                group.update_attribute(:tasks, task_string)
            end
        end

        redirect_to tasks_path
    end
    
            
            
        
        
        
    
    # def store_recent_answer_string(string)
    #     user = current_user
    #     user.update_attribute(:recent_answers, string)
    #     sign_in current_user
    # end
    # NO! DO IT IN THE SESSION.
            
            
    
    def contents(content = "",fix_to_user = 0)
        puts "content = #{content.class}"
	    # serves up an array of what to put in the view
	    things = content.split(" ")
	    things.delete("")
        output = []
	    things.each do |thing|
	        if thing[0] == "Q"
	            @question = Question.find(thing[1..-1])
	            construct(fix_to_user)
	            text = @example_question
	            prompts = @promptlist.map {|x| x.split('`')}
	            tops = prompts.map {|x| x[0]}
	            tails = prompts.map {|x| x[1]}
	            answers = @example_answers
	            output << {grouped: @grouped_answers, question: true, text: text, tops: tops, tails: tails, answers: answers.map {|x| x[0..-3] }, prec_r: answers.map {|x| x[-2..-1] }}
	        else
	            element = Element.find(thing)
	            output << {category: element.category, data: element.safe_content}
	        end
	    end
	    return output
    end
	
# 	def answer_count(contents)
# 	    contents.map { |x| x[:answers] ? x[:answers].count : 0 }.inject(0,:+)
# 	end
	
	    
    
    Array.class_eval do
      def paginate(page = 1, per_page = 15)
        WillPaginate::Collection.create(page, per_page, size) do |pager|
          pager.replace self[pager.offset, pager.per_page].to_a
        end
      end
    end
    
    def item_params
        params.require(:task).permit(:name, :content, :author)
    end
    
    def new
        @content = params[:content]||""
        new_id = params[:new_id]
        case params[:new_thing]
            when "question" 
            @content << " Q#{new_id}"
            when "element" 
            @content << " #{new_id}"
        end
        @task = Task.new
        @elements = Element.all
        @questions = Question.search(params[:search],params[:onlyme],current_user.id).order(sort_column + ' ' + sort_direction).paginate(page: params[:qpage]||1, per_page:10)
        @elements = Element.search(params[:search],params[:onlyme],current_user.id).order(sort_column + ' ' + sort_direction).paginate(page: params[:epage]||1, per_page:10)
        @contents = contents(@content,1)
        @n_contents = @contents.count
        #@answers = params[:ans] || Hash.new('')

    end

    
    def create
        @task = Task.new(params[:task])
        if @task.save
            flash.now[:success] = "Task created."
            redirect_to @task
        else
            flash.now[:notice] = "Task NOT created."
            @elements = Element.all
            @questions = Question.search(params[:search],params[:onlyme],current_user.id).all.paginate(params[:qpage]||1, 10)
            @elements = Element.search(params[:search],params[:onlyme],current_user.id).all.paginate(params[:epage]||1, 10)
            @content = @task.content
            @contents = contents(@task.content)
            render 'new'
        end
    end

    def edit
        @content = params[:content]||""
        new_id = params[:new_id]
        case params[:new_thing]
            when "question" 
            @content << " Q#{new_id}"
            when "element" 
            @content << " #{new_id}"
        end
        id = params[:id].to_i
        @task = Task.find(id)
        @elements = Element.all
        @questions = Question.search(params[:search],params[:onlyme],current_user.id).order(sort_column + ' ' + sort_direction).paginate(page: params[:qpage]||1, per_page:10)
        @elements = Element.search(params[:search],params[:onlyme],current_user.id).order(sort_column + ' ' + sort_direction).paginate(page: params[:epage]||1, per_page:10)
        
        @content = params[:content]||@task.content
        @contents = contents(@content,1)
        @n_contents = @contents.count || 0
        #@answers = params[:ans] || Hash.new('')

    end
    def update
        @task = Task.find(params[:id])
        if @task.update_attributes(params[:task])
            flash.now[:success] = "Task created."
            redirect_to @task
        else
            flash.now[:notice] = "Task NOT created."
            @elements = Element.all
            @questions = Question.search(params[:search],params[:onlyme],current_user.id).all.paginate(params[:qpage]||1, 10)
            @elements = Element.search(params[:search],params[:onlyme],current_user.id).all.paginate(params[:epage]||1, 10)
            @content = @task.content
            @contents = contents(@task.content)
            render 'edit'
        end
    end

    
    # def show
    #     @user =  current_user
    #     id = params[:id]
    #     @task = Task.find(id)
    #     #redirect_to current_user_path unless @task
    #     @contents = contents(@task.content,1)
    #     answer_n = answer_count(@contents)
    #     @ans_look_up = {}
    #     @que_look_up = {}
    #     n = m = 0
    #     question_count = 0
        
                    
    #     @oldanswers = params[:oldans] ? params[:oldans].split('|').map {|x| x.strip } : []
    #     @answers = Array.new(answer_n) {''}

    #     @contents.count.times do |i|
    #         thing = @contents[i]
    #         if thing[:question]
    #             question_count += 1
    #             @que_look_up[i] = n
    #             n += 1
    #             thing[:answers].count.times do |j|
    #                 @ans_look_up[[i,j]] = m
    #                 if @oldanswers[m]
    #                     @answers[m] = @oldanswers[m] 
    #                 else
    #                     @oldanswers[m] = ''
    #                 end
    #                 m += 1
    #             end
    #         end
    #     end
        
    #     @data = task_data(@user,id, question_count, nil)

    #     if !@data
            
    #         @data = {}
    #         @data[:resets] = 0
    #         answer_n.times do |i|
    #             @data[i] = 0
    #             @oldanswers[i]||=''
    #             @answers[i] = @oldanswers[i]
    #         end
    #     end
        
    #     resets_needed = false
    #     @contents.count.times do |i|
    #         thing = @contents[i]
    #         if thing[:question]
    #             thing[:scores] = []
    #             success = -2
    #             attempted = false
    #             n = thing[:answers].count
    #             ans = params["ans#{i}".to_s] || Hash.new(nil)
    #             n.times do |j|
    #                 answer_pos = @ans_look_up[[i,j]]
    #                 @answers[answer_pos] = ans[j] if ans[j]
    #                 user_answer = @answers[answer_pos]
    #                 attempted = true if user_answer != @oldanswers[answer_pos] and user_answer != ""
    #             end
                 
    #             n.times do |j|
    #                 user_answer = @answers[@ans_look_up[[i,j]]]
    #                 ans = thing[:answers][j]
    #                 result = match(user_answer, ans, thing[:prec_r][j])
    #                 result = -1 if user_answer == '' and !attempted
    #                 if thing[:grouped]
    #                     success = [success, result].max
    #                     thing[:scores] << ((j == n - 1) ? success : nil)
    #                 else
    #                     thing[:scores] << result
    #                     if result == 2
    #                         success = 2
    #                     elsif result == -1
    #                         if success < 0
    #                             success = -1
    #                         else
    #                             success = 2
    #                         end
    #                     elsif success == -1
    #                         success = 2
    #                     elsif success < 1
    #                         success = result
    #                     end
    #                 end
 
    #             end
    #             if success == 2
    #                 @data[@que_look_up[i]] += 1 unless @data[@que_look_up[i]] < 0
    #                 if @data[@que_look_up[i]] >= 3
    #                     @data[:resets] += 1
    #                     resets_needed = true
    #                     @data[@que_look_up[i]] = 0
    #                 end
                        
    #             elsif success == 0
    #                 @data[@que_look_up[i]] = -1
    #             end
    #         end
    #     end
    #     @data[:complete] = (1..question_count).count {|i| @data[@que_look_up[i]] != -1} == 0 
    #     @noodoo =  @answers
    #     if resets_needed
    #         current_user.reseed
    #         sign_in current_user
    #         @reset = true
    #         flash[:alert] = "Number of attempts exceeded on at least one question. All numbers reset."
    #         redirect_to @task
    #     end
    #     task_data(@user, id,  question_count, ([id, @data[:resets]] + (0..question_count-1).map {|x| @data[x] }).join(" ") )

    # end
        
    
    # def update
    #     @task = Task.find(params[:id])
    #     @contents = contents(@task.content,1)
    #     @answers = params[:@ans] || Hash.new('')
    # end
        
    # def task_data(user, task_id, question_count, new_data)
    #     #1/0 unless user
    #     user_task_data = user.task_data || ""
    #     all_task_data = user_task_data.split('|')
    #     idlen = task_id.length
    #     loc = all_task_data.index { |x| x[0..idlen] == task_id + ' ' }
    #     if loc
    #         data = all_task_data[loc].split(' ')[1..-1]
    #         if new_data
    #             new_list = all_task_data.clone
    #             new_list[loc] = new_data
    #             user.update_attribute(:task_data, new_list.join("|"))
    #             sign_in current_user
    #         end
    #         return { complete: data[0].to_i } if data.count == 1
    #         output = { resets: data[0].to_i }
    #         (1..question_count).each do |i|
    #             output[i - 1] = data[i].to_i 
    #         end
    #         puts "poopy output #{output}"
    #         return output
    #     elsif new_data
    #         all_task_data << new_data
    #         user.update_attribute(:task_data, all_task_data.join("|"))
    #         sign_in current_user
    #     end
    #     return nil
    # end
        
    
    
    
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
