class ElementsController < ApplicationController

    include ApplicationHelper

	helper_method :sort_column, :sort_direction
    before_filter :author_user
    before_filter :abandon_course_build

    def destroy
        Element.find(params[:id]).destroy
        flash[:success] = "Element destroyed."
        redirect_to elements_path
    end

    def index
        #@elements = Element.paginate(page: params[:page])
        params[:sort]||='id'
        params[:direction]||='desc'

        # @videos=Element.find(:all)
        # @videos.each do |v|
        #     if v[:category]=="video"&&v[:content].match(/\Ahttps:\/\/www\.youtube\.com\/.*\z/)
        #         v.update_attribute(:content,"http"+v[:content][5..-1])
        #     end
        # end



        @elements = Element.search(params[:search],params[:onlyme],current_user.id).order(params[:sort] + ' ' + params[:direction]).paginate(per_page: number_per_page, page: params[:page])
        
    end


    def show
    	@element = Element.find(params[:id])
        session[:new_element_id]= @element.id.to_s
    end

    def edit
        @element = Element.find(params[:id])
    end

    def update
        @element = Element.find(params[:id])
        if @element.update_attributes(params[:element])
            if naughty_content?(@element)
                flash.now[:failure] ="Element update attempted, but "+@flash_text
                @element.update_attribute(:content, "")
                @element.update_attribute(:safe_content, "")
                render "edit"
            else
                flash.now[:success] = "element updated."
                @element.update_attribute(:safe_content, @element.content) 
                redirect_to @element
            end

        end
    end


	def new
        @element = Element.new
    end

    def create
        @element = Element.new(params[:element])
        tags = @element.tags
        if params["htmlstring"] != ""
            oldcode = ""
            t = params["htmlstring"].split("u003c")
            data = []

            t.each do |u|
                v = u.split(/video_id=([^\\]+)/)
                tycode = v[1]
                if tycode and tycode != oldcode
                    oldcode = tycode
                    title = v[2].split('\\')[-1][5..-1]
                    nam = title
                    link = "https://www.youtube.com/embed/" + tycode + "?rel=0"
                    unless Element.find_by_content(link)
                        i = 1
                        until !Element.find_by_name(nam)
                            nam = title + "(#{i})"
                            i += 1
                        end
                        data << [nam,link]
                    end


                end
            end
            data.reverse.each do |nam,link|
                @el = Element.new
                @el.update_attribute(:name , nam)
                @el.update_attribute(:tags , tags)
                @el.update_attribute(:category , "video")
                @el.update_attribute(:content , link)
                @el.update_attribute(:safe_content , link)
                @el.update_attribute(:author, current_user.id) if current_user
                @el.save
            end
            redirect_to action: "index"
        else
            if current_user
                @element.update_attribute(:author, current_user.id)
            end
            if @element.save
                
                if naughty_content?(@element)
                    flash.now[:failure] ="Element created, but "+@flash_text
                    @element.update_attribute(:content, "")
                    @element.update_attribute(:safe_content, "")
                    render "edit"
                else
                    flash.now[:success] = "element created."
                    @element.update_attribute(:safe_content, @element.content) 
                    redirect_to @element
                end
            else
                render 'new'
            end
        end
    end

    def update_tags
        taglist = params[:tags]
        idlist = params[:id]
        n = taglist.count
        n.times do |i|
            id, tag = idlist[i], taglist[i]
            element = Element.find(id)
            element.update_attribute(:tags, tag)
        end
        redirect_to action: "index"
    end

    def add_to_item


        #@element = Element.find(params[:id])
        
        @item=Item.find_by_id(session[:current_item_id])
        @item[:content]=(arrayify_item_content(@item[:content]) << (params[:element]).to_s).to_s
        @item.update_attributes(params[:item])

        flash.now[:success] = "Added Element "+params[:element].to_s+" to Item "+@item.id.to_s
        index
        session[:new_element_id]=nil
        render "index"
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

    def naughty_content?(element)
        if element[:category]=="text"
            if element[:content].gsub(/<\/?(div[^>]*|h\d+|br)>/,"").match(/.*<.*>.*/)
                @flash_text = 'for html safeness please avoid using "< ... >". You can use MathJax \\gt and \\lt. Please resubmit content.'
                true
            else
                false
            end
        elsif element[:category]=="image"
            if element[:content].match(/\Ahttp:\/\/i970\.photobucket\.com\/albums\/.*\.((png)|(jpg)|(gif))\z/)
                false
            else
                @flash_text = "Only png, gif and jpg files with urls starting 'http://i970.photobucket.com/albums' currently allowed. Please resubmit content."
                true
            end
        elsif element[:category]=="video"
            if element[:content].match(/\A(http:\/\/www\.dailymotion\.com\/.*)|((http:|https:)?(\/\/)?(www\.youtube\.com|youtu\.be)\/.*)\z/)
                if element[:content].match(/\A\/\/www\.youtube\.com\/.*\z/)
                    element[:content]="https:"+element[:content]
                end
                if element[:content].match(/\Awww\.youtube\.com\/.*\z/)
                    element[:content]="https://"+element[:content]
                end
                if element[:content].match(/\Ahttp:\/\/www\.youtube\.com\/.*\z/)
                    element[:content]="https"+element[:content][5..-1]
                end
                if element[:content].match(/\Ahttps:\/\/www\.youtube\.com\/.*\z/)
                    unless element[:content].match(/.*?rel=0\z/)
                        element[:content]=element[:content]+"?rel=0"
                    end
                end
                false
            else
                @flash_text = "Only YouTube and DailyMotion videos currently allowed. Please resubmit content."
                true
            end
        else
            true
        end
    end
end