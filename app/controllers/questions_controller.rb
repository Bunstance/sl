include Math

class QuestionsController < ApplicationController
include ApplicationHelper
helper_method :sort_column, :sort_direction
before_filter :author_user

    def question(oldhash)
        #adapt params[:question][:answers]so as to encode info from params[:answers]
        # params[:grouped] and params[:order_matters]
        newhash = oldhash.clone
        options = {}
        array = []
        tops = newhash[:tops]
        answers = newhash[:answers]
        tails = newhash[:tails]
        tops.count.times do |i|
            element = {}
            element[:top] = tops[i]
            element[:answer] = answers[i]
            element[:tail] = tails[i]
            array << element
        end
        options[:grouped] = true if oldhash[:grouped]
        options[:order_matters] = true if oldhash[:order_matters]
        newhash[:question][:answers]=answer_encode(array,options)
        return newhash
    end

    def setup
        @options,@ans_array = answer_decode(@question.answers)
        @n_parts = (params[:n_parts]|| @ans_array.count).to_i
        @n_parts = 1 if @n_parts < 1
        while @n_parts > @ans_array.count
            @ans_array << {top:"",tail:"",answer:""}
        end
    end


    def show
        @question = Question.find(params[:id])
        setup
        session[:new_element_id]= "Q"+@question.id.to_s
        begin    
            construct(0)
        rescue
            flash.now[:warning] = "There was a problem with this question. Please review and update it."
            #@question.destroy
            render 'edit'

        else

            if @error 
                flash.now[:success] = "There was a problem with this question. Please address the issues below."
                @question.destroy
                render 'edit'
     	    else
                
                @question.update_attributes(params[:question])
                render 'show'
            end
        end

    end

    def edit

        @question = Question.find(params[:id])
        setup

        #@question.update_attributes(params[:question])
        construct(0)


        # if @error
        #     render 'edit'
        # else
            
        #     render 'edit'
        # end
    end

    def destroy
        Question.find(params[:id]).destroy
        flash[:success] = "Question destroyed."
        redirect_to questions_path
    end

    def index
        params[:sort]||='id'
        params[:direction]||='desc'
        @questions = Question.search(params[:search],params[:onlyme],current_user.id).order(params[:sort] + ' ' + params[:direction]).paginate(per_page: number_per_page, page: params[:page])
    end

    def update
        #@testtext=calculate('-2-1/(2-4*(2+ln(2)))')
        if params[:change_n_parts]
            redirect_to edit_question_path(params)
        else
    
     

            @question = Question.find(params[:id])
            setup
            #params[:question][:answers].gsub!('`',punc1)
            # if params[:grouped] and params[:question][:answers][0] != "G"
            #     params[:question][:answers] = "G" + params[:question][:answers]
            # elsif !params[:grouped] and params[:question][:answers][0] == "G"
            #     params[:question][:answers] = params[:question][:answers][1..-1]
            # end

            if @question.update_attributes(question(params)[:question])
                if naughty_text?(@question)
                    flash.now[:failure] ="Question update attempted, but "+@flash_text
                    @question.update_attribute(:text, "")
                    @question.update_attribute(:safe_text, "")
                    render "edit"
                else
                    
                    @question.update_attribute(:safe_text, @question.text)
                    begin    
                        construct(0)
                    rescue
                        flash.now[:warning] = "There was a problem with this question. Please review and update it."
                        #@question.destroy
                        render 'edit'
                    else
                        if @error
                            flash.now[:failure] = "There was a problem with this question"
                            render 'edit'
                        else
                            flash.now[:success] = "The website could not detect a problem with this question. But what does a website know? Please check thoroughly and refresh the page if appropriate to explore the effect of different parameter choices."
                            render 'show'
                        
                        end
                    end    
                end
                
            else
                flash.now[:failure] = "There was a problem with this question"
                render 'edit'
            end
        end

    end


    # def edit
    #     @question = Question.find(params[:id])
    # end

    # def update
    #     @question = Question.find(params[:id])
    #     if @question.update_attributes(params[:question])
    #         # Handle a successful update.
    #     else
    #         render 'edit'
    #     end
    # end


    def new
        @question = Question.new
        if params[:format]
            id=@question.id
            prev_question=Question.find(params[:format])
            @question.name=prev_question.name+' - copy'
            @question.text=prev_question.text
            @question.parameters=prev_question.parameters
            @question.tags=prev_question.tags
            @question.answers=prev_question.answers
            @question.precision_regime=prev_question.precision_regime
            @question.id=id
            setup
        end
        @n_parts ||= 3
        @ans_array ||= [{},{},{}]
    end

    def create
        @question = Question.new(question(params)[:question])
        if current_user
            @question.update_attribute(:author, current_user.id)
        end
        if @question.save
            if naughty_text?(@question)
                flash.now[:failure] ="Question created, but "+@flash_text
                @question.update_attribute(:text, "")
                @question.update_attribute(:safe_text, "")
                render "edit"
            else
                flash.now[:success] = "question created."
                @question.update_attribute(:safe_text, @question.text) 
                redirect_to @question
            end
        else
            render 'new'
        end
    end

    def add_to_item
        @item=Item.find_by_id(session[:current_item_id])
        @item[:content]=(arrayify_item_content(@item[:content]) << ("Q"+params[:question]).to_s).to_s
        @item.update_attributes(params[:item])
        flash.now[:success] = "Added Question "+"Q"+params[:question].to_s+" to Item "+@item.id.to_s
        index
        session[:new_element_id]=nil
        render "index"
    end

    def naughty_text?(question)
        if question[:text].match(/.*<.*>.*/)
            @flash_text = 'for html safeness please avoid using "< ... >". You can use MathJax \\gt and \\lt. Please resubmit content.'
            true
        else
            false
        end
        
    end

    private

    def sort_direction
        %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
    end

    def sort_column
        Element.column_names.include?(params[:sort]) ? params[:sort] : "name"
    end

    def author_user
        if current_user
            redirect_to(root_path) unless current_user.author
        else
            redirect_to(signin_path)
        end
    end
end
