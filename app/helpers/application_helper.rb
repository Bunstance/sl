module ApplicationHelper

    include Math

    include ActionView

    require 'rubystats'


    def physics_mode
        false
    end

    def https_mode
        true
    end
    
    def punc1
        29.chr
    end
    def punc2
        30.chr
    end
    def punc3
        31.chr
    end

    def answer_encode(array,options)
        array.delete({top:"",tail:"",answer:""})
        string = array.map {|hash| "["+hash[:top]+punc1+hash[:tail]+"]"+hash[:answer]} .join("")
        string = "G"+string if options[:grouped]
        string += "t" if options[:order_matters]
        return string
    end

    def answer_decode(string)
        options = {}
        if string[0]=="G"
            options[:grouped]= true
            string = string [1..-1]
        end
        if string[-1]=="t"
            options[:order_matters] = true
            string = string[0..-2]
        end
        array=[]
        while string != ""
            hash = {top:"",tail:"",answer:""}
            breakpoint = string.index("]")
            if breakpoint
                toptail = string[0..breakpoint].split(punc1)
                hash[:top] = toptail[0][1..-1]
                if toptail[1]
                    hash[:tail] = toptail[1][0..-2]
                else
                    hash[:tail] = ""
                end
                string = string[breakpoint+1 .. -1]
                endpoint = (string.index("[")||string.length) - 1
                hash[:answer] = string[0..endpoint]
                string = string[endpoint+1..-1]
            end
            array << hash unless hash == {top:"",tail:"",answer:""}
        end
        [options,array]
    end

    def insert_snippet_values(string)
        delimcount=string.count('`')
        if delimcount==0
            outputstring=string
        else
            if delimcount.modulo(2)==1
                @error=true
                throw :question_problem, 'ERROR: Invalid question text. ` must occur in pairs.'
            end
            outputstring=''
            unless string[0]=='`'
                split_pos=string.index('`')
                outputstring=string[0..(split_pos-1)]
                string=string[split_pos..-1]
            end
            while string.count('`')>0
                string=string[1..-1]
                split_pos=string.index('`')
                formula = string[0..split_pos-1]
                if formula[-1]=='f'
                    formula=formula[0..-2]
                    float=true
                else
                    float=false
                end
                
                if @example_param_hash==nil
                    @error=true
                    throw :question_problem, "ERROR: No valid parameters defined"
                end

                @example_param_hash.each {|name,value| formula.gsub!(name,value.to_s)}               
                if  formula.match(/[A-Z]/)
                    @error=true
                    throw :question_problem, "ERROR: Question contains formula with undefined parameter"
                else
                    formula_result=calculate(formula,@question.precision_regime)
                    formula_result=formula_result.to_f if float
                    outputstring=outputstring+formula_result.to_s
                    string=string[split_pos+1..-1]
                    unless string==nil
                        if string.count('`')>0
                           split_pos=string.index('`')
                           outputstring=outputstring+string[0..split_pos-1]
                           string=string[split_pos..-1]
                        else outputstring=outputstring+string
                          string=''
                        end
                    else
                    string=""
                    end
                end
                outputstring.gsub!('+-','-')
                outputstring.gsub!('-+','-')
                outputstring.gsub!('++','+')
                outputstring.gsub!('--','+')
            end
            outputstring=outputstring+string
        end
        return outputstring
    end





    def classic_mode
        false
    end

    def sortable(column, title = nil,anchor = nil)
        title ||= column.titleize
        css_class = (column == sort_column) ? "current #{sort_direction}" : nil
        direction = (column == sort_column && sort_direction == "desc") ? "asc" : "desc"
        url_options = {:sort => column, :direction => direction, :page => nil, :content => @content}
        html_options = {:class => css_class}
        if anchor
            url_options[:anchor] = html_options[:id] = anchor
        end
        link_to title, url_options, html_options
    end
    
    def feedback_text
        #{0 => "Everything is going well", 1 => "Things are OK, but I know I can do better", 2 => "I feel maths is going badly for me"}
        #{0 => "Everything worked pretty fast and well", 1 => "Not too bad", 2 => "It was annoyingly slow"}  
        {0 => "Better than MyMaths", 1 => "About the same as MyMaths", 2 => "I prefer MyMaths"}  
    end

    def feedback_interval
        3.weeks
    end

    def number_per_page
        15
    end
        

    def arglist(string)
        return string.split(/<(\d+\/\d+)>/)-['']
    end

    def tableise(string)
        list = arglist(string)
        rows = list.join('').split('|')
        return rows.map {|x| x.split(',').map {|y| y.to_i}}
    end


    def pearson(array1,array2)
        n = array1.count
        sx = array1.inject(0,:+).to_f
        sy = array2.inject(0,:+).to_f
        sxx = array1.map {|x| x.to_f*x}.inject(0,:+) - (sx*sx)/n
        syy = array2.map {|y| y.to_f*y}.inject(0,:+) - (sy*sy)/n
        sxy = array1.zip(array2).map {|pair| pair[0]*pair[1]}.inject(0,:+).to_f - (sx*sy)/n 
        return (sxy/((sxx*syy)**0.5)).to_r
    end

    def pmcc(string)
        table = tableise(string)
        return pearson(table[0],table[1])
    end

    def spearman(string)
        table = tableise(string)
        pairs = table[0].zip(table[1])
        n = pairs.count
        2.times do |i|
            pairs.sort! {|a,b| a[i] <=> b[i]}
            j = 0
            while j < n
                value = pairs[j][i]
                k = j
                while pairs[k] and pairs[k][i] == value
                    k += 1
                end
                m = k - j
                tiedrank = j + (m+1).to_r/2
                m.times do |k|
                    pairs[j + k][i] = tiedrank
                end
                j += m
            end
        end
        a,b = [0,1].map {|x| pairs.map {|y| y[x]}}
        puts "#{a}  #{b}"
        return pearson(a,b)


    end

    def chiexpected(table,pos = nil)
        n_rows = table.count
        n_cols = table[0].count
        row_total = table.map {|x| x.inject(:+)}
        col_total = (0..n_cols-1).map {|x| table.map {|y| y[x]}.inject(:+)}
        total = row_total.inject(:+)
        expected = (0..n_rows-1).map {|x| (0..n_cols-1).map {|y| (row_total[x].to_r * col_total[y])/total}}
        if pos
            return expected[pos[0]][pos[1]]
        else
            return expected
        end
    end


    def chistat(string)
        table = tableise(string)
        n_rows = table.count
        n_cols = table[0].count
        expected = chiexpected(table)
        yatesy = (n_cols == 2 and n_rows == 2) ? 0.5 : 0
        return ((0..n_rows-1).map {|x| (0..n_cols-1).map {|y| ((table[x][y]-expected[x][y]).abs - yatesy)**2/expected[x][y]}.inject(:+)}.inject(:+))
    end

    def chiexp(string)
        list = arglist(string)
        pos = [list[0],list[2]].map {|x| x.to_i - 1}
        list = list [4..-1]
        rows = list.join('').split('|')
        table = rows.map {|x| x.split(',').map {|y| y.to_i}}
        n_rows = table.count
        n_cols = table[0].count
        return chiexpected(table,pos)
    end

    def chicrit(string)
        list = arglist(string)
        dof = list[0].to_i
        ppair = list[2].split("/").map(&:to_i)
        prob = ppair[0].to_r/ppair[1]
        str = "#{[dof,prob]}"
        chihash =  {"1, (9/10)"=>2.706, "1, (19/20)"=>3.841, "1, (39/40)"=>5.024, "1, (99/100)"=>6.635, "1, (199/200)"=>7.879, "2, (9/10)"=>4.605, "2, (19/20)"=>5.991, "2, (39/40)"=>7.378, "2, (99/100)"=>9.21, "2, (199/200)"=>10.597, "3, (9/10)"=>6.251, "3, (19/20)"=>7.815, "3, (39/40)"=>9.348, "3, (99/100)"=>11.345, "3, (199/200)"=>12.838, "4, (9/10)"=>7.779, "4, (19/20)"=>9.488, "4, (39/40)"=>11.143, "4, (99/100)"=>13.277, "4, (199/200)"=>14.86, "5, (9.to_r/10).to_r"=>9.236, "5, (19/20)"=>11.07, "5, (39/40)"=>12.833, "5, (99/100)"=>15.086, "5, (199/200)"=>16.75, "6, (9/10)"=>10.645, "6, (19/20)"=>12.592, "6, (39/40)"=>14.449, "6, (99/100)"=>16.812, "6, (199/200)"=>18.548, "7, (9/10)"=>12.017, "7, (19/20)"=>14.067, "7, (39/40)"=>16.013, "7, (99/100)"=>18.475, "7, (199/200)"=>20.278, "8, (9/10)"=>13.362, "8, (19/20)"=>15.507, "8, (39/40)"=>17.535, "8, (99/100)"=>20.09, "8, (199/200)"=>21.955, "9, (9/10)"=>14.684, "9, (19/20)"=>16.919, "9, (39/40)"=>19.023, "9, (99/100)"=>21.666, "9, (199/200)"=>23.589, "10, (9/10)"=>15.987, "10, (19/20)"=>18.307, "10, (39/40)"=>20.483, "10, (99/100)"=>23.209, "10, (199/200)"=>25.188, "11, (9/10)"=>17.275, "11, (19/20)"=>19.675, "11, (39/40)"=>21.92, "11, (99/100)"=>24.725, "11, (199/200)"=>26.757, "12, (9/10)"=>18.549, "12, (19/20)"=>21.026, "12, (39/40)"=>23.337, "12, (99/100)"=>26.217, "12, (199/200)"=>28.3, "13, (9/10)"=>19.812, "13, (19/20)"=>22.362, "13, (39/40)"=>24.736, "13, (99/100)"=>27.688, "13, (199/200)"=>29.819, "14, (9/10)"=>21.064, "14, (19/20)"=>23.685, "14, (39/40)"=>26.119, "14, (99/100)"=>29.141, "14, (199/200)"=>31.319, "15, (9/10)"=>22.307, "15, (19/20)"=>24.996, "15, (39/40)"=>27.488, "15, (99/100)"=>30.578, "15, (199/200)"=>32.801, "16, (9/10)"=>23.542, "16, (19/20)"=>26.296, "16, (39/40)"=>28.845, "16, (99/100)"=>32.0, "16, (199/200)"=>34.267, "17, (9/10)"=>24.769, "17, (19/20)"=>27.587, "17, (39/40)"=>30.191, "17, (99/100)"=>33.409, "17, (199/200)"=>35.718, "18, (9/10)"=>25.989, "18, (19/20)"=>28.869, "18, (39/40)"=>31.526, "18, (99/100)"=>34.805, "18, (199/200)"=>37.156, "19, (9/10)"=>27.204, "19, (19/20)"=>30.144, "19, (39/40)"=>32.852, "19, (99/100)"=>36.191, "19, (199/200)"=>38.582, "20, (9/10)"=>28.412, "20, (19/20)"=>31.41, "20, (39/40)"=>34.17, "20, (99/100)"=>37.566, "20, (199/200)"=>39.997, "21, (9/10)"=>29.615, "21, (19/20)"=>32.671, "21, (39/40)"=>35.479, "21, (99/100)"=>38.932, "21, (199/200)"=>41.401, "22, (9/10)"=>30.813, "22, (19/20)"=>33.924, "22, (39/40)"=>36.781, "22, (99/100)"=>40.289, "22, (199/200)"=>42.796, "23, (9/10)"=>32.007, "23, (19/20)"=>35.172, "23, (39/40)"=>38.076, "23, (99/100)"=>41.638, "23, (199/200)"=>44.181, "24, (9/10)"=>33.196, "24, (19/20)"=>36.415, "24, (39/40)"=>39.364, "24, (99/100)"=>42.98, "24, (199/200)"=>45.559, "25, (9/10)"=>34.382, "25, (19/20)"=>37.652, "25, (39/40)"=>40.646, "25, (99/100)"=>44.314, "25, (199/200)"=>46.928, "26, (9/10)"=>35.563, "26, (19/20)"=>38.885, "26, (39/40)"=>41.923, "26, (99/100)"=>45.642, "26, (199/200)"=>48.29, "27, (9/10)"=>36.741, "27, (19/20)"=>40.113, "27, (39/40)"=>43.195, "27, (99/100)"=>46.963, "27, (199/200)"=>49.645, "28, (9/10)"=>37.916, "28, (19/20)"=>41.337, "28, (39/40)"=>44.461, "28, (99/100)"=>48.278, "28, (199/200)"=>50.993, "29, (9/10)"=>39.087, "29, (19/20)"=>42.557, "29, (39/40)"=>45.722, "29, (99/100)"=>49.588, "29, (199/200)"=>52.336, "30, (9/10)"=>40.256, "30, (19/20)"=>43.773, "30, (39/40)"=>46.979, "30, (99/100)"=>50.892, "30, (199/200)"=>53.672, "31, (9/10)"=>41.422, "31, (19/20)"=>44.985, "31, (39/40)"=>48.232, "31, (99/100)"=>52.191, "31, (199/200)"=>55.003, "32, (9/10)"=>42.585, "32, (19/20)"=>46.194, "32, (39/40)"=>49.48, "32, (99/100)"=>53.486, "32, (199/200)"=>56.328, "33, (9/10)"=>43.745, "33, (19/20)"=>47.4, "33, (39/40)"=>50.725, "33, (99/100)"=>54.776, "33, (199/200)"=>57.648, "34, (9/10)"=>44.903, "34, (19/20)"=>48.602, "34, (39/40)"=>51.996, "34, (99/100)"=>56.061, "34, (199/200)"=>58.964, "35, (9/10)"=>46.059, "35, (19/20)"=>49.802, "35, (39/40)"=>53.203, "35, (99/100)"=>57.342, "35, (199/200)"=>60.275, "36, (9/10)"=>47.212, "36, (19/20)"=>50.998, "36, (39/40)"=>54.437, "36, (99/100)"=>58.619, "36, (199/200)"=>61.581, "37, (9/10)"=>48.363, "37, (19/20)"=>52.192, "37, (39/40)"=>55.668, "37, (99/100)"=>59.892, "37, (199/200)"=>62.883, "38, (9/10)"=>49.513, "38, (19/20)"=>53.384, "38, (39/40)"=>56.896, "38, (99/100)"=>61.162, "38, (199/200)"=>64.181, "39, (9/10)"=>50.66, "39, (19/20)"=>54.572, "39, (39/40)"=>58.12, "39, (99/100)"=>62.428, "39, (199/200)"=>65.476, "40, (9/10)"=>51.805, "40, (19/20)"=>55.758, "40, (39/40)"=>59.342, "40, (99/100)"=>63.691, "40, (199/200)"=>66.766, "45, (9/10)"=>57.505, "45, (19/20)"=>61.656, "45, (39/40)"=>65.41, "45, (99/100)"=>69.957, "45, (199/200)"=>73.166, "50, (9/10)"=>63.167, "50, (19/20)"=>67.505, "50, (39/40)"=>71.42, "50, (99/100)"=>76.154, "50, (199/200)"=>79.49, "55, (9/10)"=>68.796, "55, (19/20)"=>73.311, "55, (39/40)"=>77.38, "55, (99/100)"=>82.292, "55, (199/200)"=>85.749, "60, (9/10)"=>74.397, "60, (19/20)"=>79.082, "60, (39/40)"=>83.298, "60, (99/100)"=>88.379, "60, (199/200)"=>91.952, "65, (9/10)"=>79.973, "65, (19/20)"=>84.821, "65, (39/40)"=>89.177, "65, (99/100)"=>94.422, "65, (199/200)"=>98.105, "70, (9/10)"=>85.527, "70, (19/20)"=>90.531, "70, (39/40)"=>95.023, "70, (99/100)"=>100.425, "70, (199/200)"=>104.215, "75, (9/10)"=>91.061, "75, (19/20)"=>96.217, "75, (39/40)"=>100.839, "75, (99/100)"=>106.393, "75, (199/200)"=>110.286, "80, (9/10)"=>96.578, "80, (19/20)"=>101.879, "80, (39/40)"=>106.629, "80, (99/100)"=>112.329, "80, (199/200)"=>116.321, "85, (9/10)"=>102.079, "85, (19/20)"=>107.522, "85, (39/40)"=>112.393, "85, (99/100)"=>118.236, "85, (199/200)"=>122.325, "90, (9/10)"=>107.565, "90, (19/20)"=>113.145, "90, (39/40)"=>118.136, "90, (99/100)"=>124.116, "90, (199/200)"=>128.299, "95, (9/10)"=>113.038, "95, (19/20)"=>118.752, "95, (39/40)"=>123.858, "95, (99/100)"=>129.973, "95, (199/200)"=>134.247, "100, (9/10)"=>118.498, "100, (19/20)"=>124.342, "100, (39/40)"=>129.561, "100, (99/100)"=>135.807, "100, (199/200)"=>140.169}
        return chihash[str[1..-2]]
    end


    def plus(string)
        return string.split(',').map {|x| x[1..-2].to_r}.inject(:+)
    end

    def ln(x)
        return log(x)
    end

    def ncdf(x)
        norm = Rubystats::NormalDistribution.new(0, 1)
        norm.cdf(x)
    end

    def ninv(x)
        norm = Rubystats::NormalDistribution.new(0, 1)
        norm.icdf(x)
    end

    def lg(x)
        return log10(x)
    end

    def number(string)  
        string=string.delete ' '
        sign=1
        if  string[0]=='_' then                 # we will be using '_' for unary minus.
            sign=-1
            string=string[1..-1]
        end
        unless string.match(/\./) 
            return '<'+(string.to_r*sign).to_s+'>'
        else
            int_frac=string.split('.')
            int=int_frac[0]
            frac=int_frac[1]
            if frac==''
                return '<'+(int.to_r*sign).to_s+'>'
            else
                frac=frac.to_r/10**frac.length
                return '<'+((int.to_r+frac)*sign).to_s+'>'
            end
        end
    end

    def prepare(input)
        ourexp=input

        #This is a one-time process of tidying up the input string prior to simplification.

        #Our biggest bugbear is - signs. 

        #It will always be safe to replace '++' and '--' with '+', and '-+' and '+-' with '-'

        while ourexp.match(/[\+-][\+-]/)
            ourexp=ourexp.gsub('++','+')
            ourexp=ourexp.gsub('--','+')
            ourexp=ourexp.gsub('+-','-')
            ourexp=ourexp.gsub('-+','-')
        end

        #We need to distinguish between binary minus, which always follows a number or a ')',
        #and all other uses of -, which are unary. E.g. "-cos(-e^-3)--2" has just one binary -. We're going to use different
        #symbols to distinguish the kinds of -. We want to keep the usual symbol for subtraction, so we'll change unary minuses
        #to '_'. However, since the binary variety is the easy one to characterise, we'll swap them all first and change the
        #binary ones back.

        ourexp=ourexp.gsub('-','_')

        while ourexp.match(/[\d\.\)]_/)
            breakdown=ourexp.partition (/[\d\.\)]_/)
            ourexp=breakdown[0]+breakdown[1][0]+'-'+breakdown[2]
        end

        #While we're at it, we'll do the same for +. Unary plus is lovely - we can delete it!
        
        ourexp=ourexp.gsub('+','&')

        while ourexp.match(/[\d\.\)]&/)
            breakdown=ourexp.partition (/[\d\.\)]&/)
            ourexp=breakdown[0]+breakdown[1][0]+'+'+breakdown[2]
        end

        ourexp=ourexp.delete('&')


        ## Deal with ^-  {replace with ^(-1)^}
        ## ourexp=ourexp.gsub(/\^\-/,'^(-1)^')

        ## deal with other leading -

        ## if ourexp[0]=='-'
        ##  ourexp='(-1)*'+ourexp[1..-1]
        ## end

        ## puts ourexp, "!!!"

        ## while ourexp.match(/[^\d\)]-\d/)
        ##  puts ourexp, '%%%'
        ##  breakdown=ourexp.partition(/[^\d\)]-\d/)
        ##  puts breakdown
        ##  ourexp=breakdown[0]+breakdown[1][0]+'(-1)*'+breakdown[1][-1]+breakdown[2]
        ## end
        ## puts ourexp,'{{}}'
        

        #Unary '-'' before a number can always be sucked into the number itself.
        #Which we'll do below.

        #Meanwhile, let's decide to leave it at that. If we try to deal with e.g. cos-exp-3^2 we'd be guessing where the user
        #wanted the brackets. If you're wondering why we'd even dream of tolerating such things, the intended application is
        #evaluating algebraic formulae into which a machine has gsubbed values. So the user might want the formula to be
        #cosA + sinA, and the computer might sub in A='-3', and then we'd have cos-3.
        #But we are going to be mean to the user and insist on cos(A) etc.

        #So we'll convert all numbers to our preferred format <a/b> or <-a/b>, sucking in all the unary minuses we can.

        head=''
        tail=ourexp
        while tail.length>0
            if tail.match(/\d/)
                start=tail.index(/_?[\d\.]/)
                head=head+tail[0..start-1] if start>0
                tail=tail[start..-1]
                
                if tail.match(/\A_?[\d\.]*\z/)
                    num=tail
                    tail=''
                else
                    finish=tail[1..-1].index(/[^\d\.]/)
                    puts finish
                    num=tail[0..finish]
                    tail=tail[finish+1..-1]
                end
                
                head=head+number(num)
                
            else
                head=head+tail
                tail=''
            end
        end
        ourexp=head

        return ourexp

    end

def users_browser_ie?

       user_agent =  request.env['HTTP_USER_AGENT'].downcase 

        if user_agent.index('msie') && !user_agent.index('opera') && !user_agent.index('webtv')

           true

       else

           false
 
       end

   end


    # Returns the full title on a per page basis
    def full_title(page_title)
        base_title="StemLoops"
        if page_title.empty?
            base_title
        else
            base_title+" | "+page_title
        end
    end

    def evaluate(input) #input assumed to be a string. 
                        #Output will be a rational, by coercion if necessary
                        #expressed in the format '<a/b>'

    
        # recursively deal with all brackets.
        puts 'starting over with', input

        ourexp=input


        if ourexp.match(/\A<-?\d+\/\d+>\z/)
            puts 'handing back', ourexp
            return ourexp
        end

        while ourexp.match(/\(/) do
            breakdown=['','','']
            start=ourexp.index(/\(/)
                puts start
            if start==0
                breakdown[0]=''
                breakdown[1]=ourexp[1..-1]
            else
                breakdown[0]=ourexp[0..start-1]
                breakdown[1]=ourexp[start+1..-1]
            end
            puts 1/0 if breakdown[1]==nil  # we have a ( at the end, which is not good.
            puts breakdown, 'initial breakdown'
            count=1
            pos=0
            while count>0
                if breakdown[1][pos]=='('
                    count=count+1
                elsif breakdown[1][pos]==')'
                    count=count-1
                end
                puts 0/1 if pos>breakdown[1].length  # we have a bracket mismatch error.
                pos=pos+1
            end
            #puts pos,"*"
            if pos>breakdown[1].length
                breakdown[2]=''
                breakdown[1]=breakdown[1][0..-2]
            else
                breakdown[2]=breakdown[1][pos..-1]
                breakdown[1]=breakdown[1][0..pos-2]
            end
            print 'dealing with ',breakdown[1], 'but promise not to forget ',breakdown[0], 'or', breakdown[2]
            #If there is a unary '-' in front of this bracket, we'll take the chance to deal with it.

            if breakdown[0]==''
                ourexp=breakdown[0]+evaluate(breakdown[1])+breakdown[2]
            elsif breakdown[0][-1]=='_'
                ourexp=breakdown[0][0..-2]+'(<-1/1>*'+evaluate(breakdown[1])+')'+breakdown[2]
            else
                ourexp=breakdown[0]+evaluate(breakdown[1])+breakdown[2]  ##Yes, I know.
            end

           # puts 'bbb', breakdown, 'bbb'


        
           # puts ourexp, 'after bracket removed'
        end

        if ourexp.match(/\A<-?\d+\/\d+>\z/)
          #  puts 'handing back', ourexp
            return ourexp
        end


        ourexp=ourexp.gsub(/e\^/,'exp')
        


    #deal with mulit-var functions
        ['plus','chicrit','chistat','chiexp','pmcc','spearman'].each do |func|
            reg = Regexp.new('('+func+'{[^}]*})')
            parts = ourexp.split reg
            puts "#{parts}"
            n = parts.count
            n.times do |i|
                if parts[i].match reg
                    puts func + '("'+ parts[i].match(Regexp.new(func+'{([^}]*)}'))[1]+'")'
                    puts "poop #{eval('plus("<2/1>,<5/1>")')}"
                    parts[i] = "<"+eval(func + '("'+ parts[i].match(Regexp.new(func+'{([^}]*)}'))[1]+'")').to_r.to_s+">"
                    puts "****** #{parts[i]} *******"
                end
            end
            ourexp = parts.join('')
        end


    #deal with single-var functions
        ['acos','asin','atan','sin','cos','tan','log','exp','ln','lg','ncdf','ninv'].each do |func|
           # puts func
            if ourexp.match(func+'[^<]')
                x=1/0
            end
            ourexp=ourexp.gsub(func,'~#~')
         #   puts ourexp
        

         #   puts 'got to 66'
            
            while ourexp.match(/~#~/)
                breakdown=ourexp.partition(/~#~/)
                if breakdown[2]=="" 
                    #function has no argument  
                    x=1/0
                end
                subbreak=breakdown[2].partition(/>/)
                #puts subbreak, '@@@'
                if subbreak[0]==""  
                    #function has no argument 
                    x=1/0
                end
                #let's not miss the chance to nail a unary minus
                # unless breakdown[0]==''
                #   if breakdown[0][-1]=='_'
                #       breakdown[0]=breakdown[0][0..-2]+'<-1/1>*'
                #   end
                # end

                # except it doesnt work e.g. in 3/-exp(6). We'll have to deal with /- and *- as special cases later.

                if subbreak[0].match(/\A<-?\d+\/\d+\z/)
                    #puts func+'('+subbreak[0][1..-1]+'.to_r)','*&*&**'
                    ourexp=breakdown[0]+ "<" + eval(func+'('+subbreak[0][1..-1]+'.to_r)').to_r.to_s + subbreak[1]+subbreak[2]
                    #puts func,ourexp,"!!!!!!"
                else
                    x=1/0 # we insist on brackets after these functions, so by this stage they'd jolly well be followed by just a number.
                    #ourexp=breakdown[0]+ "~#~"+ evaluate(subbreak[0]+'>')+subbreak[1][1..-1]+subbreak[2]### need to fix so we're evaluating the argument of the func
                    #puts ourexp
            
                end
            end
        end

        
    puts 'got to 89'
        if ourexp.match(/\A<-?\d+\/\d+>\z/)
            #puts 'handing back', ourexp
            return ourexp
        end

        #deal with pi

        ourexp=ourexp.gsub(/pi/,'<'+PI.to_r.to_s+'>')
        #puts ourexp
        if ourexp.match(/\A<-?\d+\/\d+>\z/)
            #puts 'handing back', ourexp
            return ourexp
        end

        #deal with e's 

        ourexp=ourexp.gsub(/e/,'<'+exp(1).to_r.to_s+'>')
        #puts ourexp
        if ourexp.match(/\A<-?\d+\/\d+>\z/)
            #puts 'handing back', ourexp
            return ourexp
        end
    #puts 'got to 132'
        #deal with ^/*-+

        #'*_' and '/_' are special cases - ooooh those unary minuses!

        ourexp=ourexp.gsub(/>\*_</,'>*<-1/1>*<')
        ourexp=ourexp.gsub(/>\/_</,'>*<-1/1>/<')

        ['^','/','*','-','+'].each do #order matters
            |operator_raw|
            while ourexp.include?('>'+operator_raw+'<')
                breakdown1=ourexp.partition('>'+operator_raw+'<')   
                if operator_raw =='^'
                    operator ='**'
                else
                    operator = operator_raw
                end
                ourexp=breakdown1[0]+'```'+breakdown1[2]
                #puts ourexp

                while ourexp.match(/<-?\d+\/\d+```-?\d+\/\d+>/) do
                    breakdown=ourexp.partition(/<-?\d+\/\d+```-?\d+\/\d+>/)
                    subbreak=breakdown[1].partition(/```/)
                    value1=subbreak[0][1..-1]
                    value2=subbreak[2][0..-2]
                    #puts value1+'.to_r'+operator+value2+'.to_r','*&*'
                    value3='<'+eval('('+value1+'.to_r'+')'+operator+'('+value2+'.to_r'+')').to_r.to_s+'>'
                    ourexp=breakdown[0]+value3+breakdown[2]
                    #puts ourexp
                    if ourexp.match(/\A<-?\d+\/\d+>\z/)
            #puts 'handing back', ourexp
            return ourexp
        end
                end
            end
        end
        
        if ourexp.match(/\A<-?\d+\/\d+>\z/)
            #puts 'handing back', ourexp
            return ourexp
        end

        
    end
    def calculate(string, precision_regime)
        if precision_regime[0].downcase=="w" then return string
        end
    unless string.count('(')==string.count(')') 
        #puts string, "initial input"
        x=1/0
        #puts prepare(string), "outcome of prepare"
    end
        x=evaluate(prepare(string))[1..-2].to_r
        if precision_regime[1..-1]=='0'
            d=x.denominator
            if d==1 
                return x.numerator
            else
                return x
            end
        end
        figures=(precision_regime[1..-1]).to_i
        answer = rounded(x,figures)
        return physics_mode ? answer : answer.to_f.to_s.gsub(/\.0\z/,"")
        #return x.to_s+figures.to_s
    end

    def construct(fix_to_user)
        raise(ArgumentError, "There is no currrent user") unless current_user
        if fix_to_user > 0
            srand(@question.id+current_user.id+current_user.seed + fix_to_user)
        else
            srand()
        end 
        @error=false
        #@question = Question.find(params[:id])
        @param=@question.parameters.split(' ')
        @paramtext =''
        @param_hash={}

        @paramtext=catch(:parameter_problem) do
            if @param.count.modulo(2)==1
                @error=true
                throw :parameter_problem,'ERROR: string should have variable names and values separated by spaces.'
            end
            @example_param_hash={}
            while @param.count>1
              string1=@param[0]
              string2=@param[1]
              @param_hash[string1] = string2 if string2
              @param = @param[2..@param.count]
            end
            @param_hash.each do
                |string1, string2|
            
                unless string1.match('\A[A-Z]\z')
                    @error=true
                    throw :parameter_problem, '<h1> ERROR: Parameter names must be single uppercase letters </h1>'
                end
            
            
                @paramtext=@paramtext+string1+' is '
                if  string2.match(/\A\((-?(\d)+,)+-?(\d)+\)\z/)
                    poss=string2.split(/[^1234567890-]/)
                    poss.delete('')
                    @paramtext=@paramtext+'any of '+poss.to_s+'. '
                    value=poss.shuffle.first.to_i
                    @example_param_hash[string1]=value
                
                elsif string2.match(/\A\(-?(\d)+\.\.-?(\d)+\)\z/)
                    bounds=string2.split(/[^1234567890-]/)
                    bounds.delete('')
                    bound_l=bounds[0].to_i
                    bound_h=bounds[1].to_i
                    unless bound_l<bound_h
                        @error=true
                        throw :parameter_problem, 'ERROR: lower bound must be less than upper'
                    else
                        @paramtext=@paramtext+' an integer in the range '+bounds[0]+' to '+bounds[1]+'. '
                        value=rand(bound_l..bound_h)
                        @example_param_hash[string1]=value
                    end
                elsif string2.match(/\A\[-?(\d)+(\.(\d)+)?\.\.-?(\d)+(\.(\d)+)?\]\z/)
                    dots_pos=string2.index('..')
                    bound_l=string2[1..dots_pos-1].to_r
                    bound_h=string2[dots_pos+2..-2].to_r
                    unless bound_l<bound_h
                        @error=true
                        throw :parameter_problem, 'ERROR: lower bound must be less than upper'
                    else
                        @paramtext=@paramtext+' a real in the range '+bound_l.to_s+' to '+bound_h.to_s+'. '
                        value=rand(bound_l..bound_h)
                        @example_param_hash[string1]=value
                    end 
                end
            end
        end


    


        @example_answers=catch(:answer_problem) do
            @order_matters=false
            answers=@question.answers
            #if answers.include?('`')
                if answers[-1].match(/[tf]/)
                    @order_matters=true if answers[-1]="t"
                    answers=answers[0..-2]
                end

                if answers[0]=="G"
                    @grouped_answers=true
                    answers=answers[1..-1]
                else
                    @grouped_answers=false
                end

                @example_answers = []
                answerlist=answers.split(/\[[^\[\]]*\]/)
                answerlist.delete('')

                @promptlist=answers.scan(/\[[^\[\]]*\]/)
                (0..@promptlist.count-1).each do
                    |index|
                    @promptlist[index]=insert_snippet_values(@promptlist[index][1..-2])
                end

                answerlist.each do
                    |this_answer|
                    precision_regime=@question.precision_regime
                    if this_answer[-2] && this_answer[-2].match(/[hsrwW]/)
                        precision_regime=this_answer[-2..-1]
                        this_answer=this_answer[0..-3]
                    end

                    #if @example_param_hash==nil
                    #    @error=true
                    #    throw :answer_problem, "ERROR: No valid parameters defined"
                    #end
                    @example_param_hash.each {
                        |name,value|                           
                        this_answer.gsub!(name,value.to_f.to_s)      
                    }
                    # if this_answer.match(/[A-Z]/)
                    #     @error=true
                    #     throw :answer_problem, "ERROR: Answer uses undefined parameter(s) e.g. "+this_answer.match(/[A-Z]/)[0]
                    # end
                    #begin
                        x=calculate(this_answer,precision_regime).to_s
                        
                        @example_answers << x+precision_regime
                    #rescue
                    #    @error=true
                    #    throw :answer_problem, 'ERROR: Answer calculation '+this_answer+' causes evaluation error HERE'
                    #end
                end
                throw :answer_problem, @example_answers
            #else 
                #@example_answers=answers
            #end
        end

        @example_question=catch(:question_problem) do
            question_text=@question.safe_text
            @example_question = insert_snippet_values(question_text)
        end
            
        return [@question.text, @param_hash.to_s, @example_param_hash.to_s, @paramtext, @example_answers, @example_question,@error,@promptlist,@grouped_answers]
        
    
    end

    # def decode_answer(answer)
    #     parsed_answer={}
    #     answer_strings=answer.split(/\[[^\[\]]\]/)
    #     if answer_strings[0]==''
    #         answer_strings=answer_strings[1..-1]
    #     else
    #         parsed_answer[:errortext]=parsed_answer[:errortext]+"There is no prompt list at the start of the answer string. "
    #     end
    #     parsed_answer[:answers]=[]
    #     parsed_answer[:answer_types]=[]
    #     parsed_answer[:notes]=[]







    def rounded(number,figs)
        if number<0
            sign ='-'
        else
            sign=''
        end
        if number==0
            answer="0"
            if figs>1
                answer=answer+'.'+'0'*(figs-1)
            end
            return answer
        end
        number = number.abs
        exponent=(log10(number)).floor
        abscissa=number.to_f/(10**exponent)
        abscissa=abscissa.round(figs-1).to_s.delete('.')
        shortness=figs-abscissa.length
        if shortness>0
            abscissa=abscissa+"0"*shortness
        end
        if exponent == figs-1
            return sign+abscissa
        elsif exponent < 0
            return sign+"0."+"0"*(-1-exponent)+abscissa
        elsif exponent >= figs
            return sign+abscissa + "0"*(exponent-figs+1)
        else
            return sign+abscissa[0..exponent]+"."+abscissa[exponent+1..-1]
        end
    end
                
      
    def match(stringx,stringy,precision_regime)
        stringy.strip!

        if precision_regime=="W0"
            if stringx==stringy
                return 0
            else
                return 2
            end
        end

        if precision_regime=="w0"
            if stringx.downcase==stringy.downcase
                return 0
            else
                return 2
            end
        end

        if precision_regime[0].downcase=='w'
            if precision_regime[0]=='w'
                stringx=stringx.downcase
                stringy=stringy.downcase
            end

            keywords=stringx.split('`')
            count=0
            keywords.each do
                |word|
                subcount=0
                alternatives = word.split('|')
                alternatives.each do
                    |alternative|
                    subcount=subcount+1 if stringy.include?(alternative)
                end
                count=count+1 if subcount>0
            end
            if count<precision_regime[1..-1].to_i
                return 2
            else
                return 0
            end
        end

        figs=precision_regime[1..-1].to_i
     
        if figs==0
            if stringx==stringy
                return 0
            elsif stringx.to_f==stringy.to_f && !stringy==''
                return 1
            else
                return 2
            end
        elsif precision_regime[0]=="h"
            if stringx==stringy
                return 0
            elsif stringx==rounded(stringy.to_f,figs)
                return 1
            else
                return 2
            end
        elsif precision_regime[0]=="r"
            if stringx==rounded(stringy.to_f,figs)||rounded(stringx.to_r.to_f,figs)==rounded(stringy.to_r.to_f,figs)
                return 0
            else
                return 2
            end
        elsif precision_regime[0]=="s"
            return 2 if ((stringx.to_f)/(stringy.to_f)-1).abs>0.5
            diff=(rounded(stringx.to_f,figs).delete('.')[0..figs-1].to_i-rounded(stringy.to_f,figs).delete('.')[0..figs-1].to_i).abs
            if diff>1
                return 2
            else
                excess_figs=stringy.delete('.').to_i.to_s.length-figs
                if excess_figs>1
                    if stringy.delete('.').to_i.to_s[-excess_figs..-1].match(/\A0*\z/)
                        return 0
                    else
                        return 1
                    end
                else
                    return 0
                end
            end
        end
    end


     def arrayify_item_content(string)
        unless string.match(/\A\[.*\]\z/)
            return []
        end
        if string=="[]"
            return []
        else
            answer=[]
            middle=string[1..-2].delete(' ')
            bits=middle.split(",")
            bits.each do
                |bit|
                bot=bit[1..-2]
                answer << bot
            end
            return answer
        end
    end

     def create_item(item)

        # create a string containing the html to display an item body
        # and spaces for answers plus feedback.
        @ans=params["@ans"]
        session[:answers]={} unless session[:answers]
        session[:items]=[] unless session[:items]
        if session[:answers][item.id.to_s]&&@ans
            session[:answers][item.id.to_s]=@ans
            session[:items].delete(item.id.to_s)
            session[:items] << item.id.to_s
        elsif @ans
            oldest=session[:items][0]
            unless session[:answers].count<6
                session[:answers].delete(oldest.to_s)
                session[:items]=session[:items][1..-1]
            end
            session[:answers][item.id.to_s]=@ans
            session[:items] << item.id.to_s
        elsif session[:answers][item.id.to_s]
            @ans=session[:answers][item.id.to_s]
        end
            


        @item_html="<form>"
        count=0
        hint_div_count=0
        content=arrayify_item_content(item.content)
        correct=0
        total=0

        @item_html=@item_html+%Q(
                <table class="table">  
                <tbody>
                )

        content.each do
            
            |item_string|

            @item_html=@item_html+" <tr> "

            hint_array=item_string.split("h")[1..-1]

            item_string=item_string.split("h")[0]

            hint_html=' '
            hint_array.each do
                |hint|
                hint_element=Element.find_by_id(hint.to_i)
                unless hint_element==nil

                    if hint_element.category=="text"
                        hint_div_count=hint_div_count+1
                        div_id="link-"+hint_div_count.to_s
                        @item_html='<div id= "'+div_id+ '" class="hide"><h3><p>'+hint_element.safe_content+'</p></h3></div>'+@item_html
                        hint_html=hint_html+'<a href="#'+div_id+'" rel="prettyPhoto" title=""><img src="http://i970.photobucket.com/albums/ae189/gumboil/website/Hintbutton-1.png" alt="Hint" width="70" /></a> '
                    end

                    if hint_element.category=="video"
                        hint_element.safe_content.gsub("http://","https://")
                        hint_element.safe_content.gsub("https://","http://") unless https_mode
                        hint_html=hint_html+'<a href="'+hint_element.safe_content+'?iframe=true&width=100%&height=100%" rel="prettyPhoto[iframes]" title="Video"><img src="http://i970.photobucket.com/albums/ae189/gumboil/website/Videobutton.png" width="70" alt="Video" /> </a>'
                    end

                    if hint_element.category=="image"
                        hint_html=hint_html+'<a href="'+hint_element.safe_content+'" rel="prettyPhoto" title="Image"><img src="http://i970.photobucket.com/albums/ae189/gumboil/website/Imagebutton.png" width="70" alt="Image" /></a>'
                    end

                    hint_html=hint_html+' <br />'

                else
                    hint_html=hint_html+'no such element as '+hint
                end

            end
            
            if item_string[0]=="Q"

                   
                @question=Question.find_by_id(item_string[1..-1].to_i)
                if @question
                    begin    
                        construct(1)
                    rescue
                        @item_html=@item_html+"<p>Something went wrong with question "+ @question.id.to_s+"</p>"
                    else
                        @item_html=@item_html+%Q(
                        
                        <p>
                        <td style="vertical-align:middle">
                        <h9>)+@example_question+%Q(</h9> </td> 
                        <td style="vertical-align:middle"> 
                        <p align="right">
                        )+hint_html+%Q(     
                        </td> 
                        </tr>
                        </tbody>
                        </table>         
                        )
                        
                        @item_html=@item_html+%Q(
                        <table class="table">  
                        <tbody>
                        )


                        if @grouped_answers

                            total=total+1

                            ans_match=nil

                            (0..@example_answers.count-1).each do
                                |index|
                                answer=@example_answers[index]

                                @precision_regime=answer[-2..-1]
                                answer=answer[0..-3]
                                if @ans && @ans[count]
                                    answer_given=@ans[count].to_s
                                else
                                    answer_given=''
                                end
                                if @promptlist[index]
                                    top_tail=@promptlist[index].split(punc1)
                                else
                                    top_tail=[]
                                end
                                if top_tail[0]
                                    top=top_tail[0]
                                else
                                    top=''
                                end
                                if top_tail[1]
                                    tail=top_tail[1]
                                else
                                    tail=''
                                end

                                @item_html=@item_html+%Q(
                                    <tr>
                                    <td style="vertical-align:middle">
                                    <h5>
                                    )
                                @item_html=@item_html+top+'</h5></td><td style="vertical-align:middle" width = "100"> <input type="textarea"  name="@ans[]" value="'+ answer_given + '" rows="1" cols="20" > </td>'
                                @item_html=@item_html+'<td style="vertical-align:middle"><h5a>'+tail+'</h5a></td>'
                                if @ans && @ans[count]
                                    ans_match=0 unless ans_match
                                    this_ans_match=match(answer,@ans[count],@precision_regime)
                                    ans_match=this_ans_match if this_ans_match>ans_match
                                    if index==@example_answers.count-1
                                        if ans_match==0
                                             @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/tick.jpg width="70" height="70" /> </p> </td>'
                                            correct=correct+1
                                        elsif ans_match==1
                                             @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/orangetriangle-1.jpg width="70" height="70" /> </p> </td>'
                                        else
                                             @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/cross.jpg width="70" height="70" /> </p> </td>'
                                        end
                                    else
                                        @item_html=@item_html+'<td></td>'
                                    end

                                end
                                count=count+1 
                                @item_html=@item_html+ '</tr>'
                            end
                            @item_html=@item_html+ '</tbody> </table>'
                            @item_html=@item_html+%Q(
                            <table class="table">  
                            <tbody>
                            <tr>
                            )
                        
                        else
                                                            
                            
                            @item_html=@item_html+%Q(
                            <table class="table">  
                            <tbody>
                            )
                            total=total+@example_answers.count

                            (0..@example_answers.count-1).each do
                                |index|
                                answer=@example_answers[index]

                                @precision_regime=answer[-2..-1]
                                answer=answer[0..-3]
                                if @ans && @ans[count]
                                    answer_given=@ans[count].to_s
                                else
                                    answer_given=''
                                end

                                top_tail=@promptlist[index].split(punc1)
                                if top_tail[0]
                                    top=top_tail[0]
                                else
                                    top=''
                                end
                                if top_tail[1]
                                    tail=top_tail[1]
                                else
                                    tail=''
                                end

                                @item_html=@item_html+%Q(
                                    <tr>
                                    <td style="vertical-align:middle">
                                    <h5>
                                    )
                                @item_html=@item_html+top+'</h5></td><td style="vertical-align:middle" width = "100"> <input type="textarea"  name="@ans[]" value="'+ answer_given + '" rows="1" cols="20" > </td>'
                                @item_html=@item_html+'<td style="vertical-align:middle"><h5a>'+tail+'</h5a></td>'
                                if @ans && @ans[count]
                                    ans_match=match(answer,@ans[count],@precision_regime)
                                    if ans_match==0
                                         @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/tick.jpg width="70" height="70" /> </p> </td>'
                                        correct=correct+1
                                    elsif ans_match==1
                                         @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/orangetriangle-1.jpg width="70" height="70" /> </p> </td>'
                                    else
                                         @item_html=@item_html+'<td> <p align="right"> <img src = http://i970.photobucket.com/albums/ae189/gumboil/cross.jpg width="70" height="70" /> </p> </td>'
                                    end
                                end
                                count=count+1
                                @item_html=@item_html+ '</tr>'
                            end
                            @item_html=@item_html+ '</tbody> </table>'
                            @item_html=@item_html+%Q(
                            <table class="table">  
                            <tbody>
                            <tr>
                            )
                        end
                    end
                else
                    @item_html=@item_html+ 'No such question as '+item_string[1..-1]
                end

        
            else
                element=Element.find_by_id(item_string.to_i)
                if element
                    category=element.category
                    if category=="text"
                        content_html=' <h9> '+ element.safe_content+ ' </h9> '
                        #@item_html=@item_html+%Q(
                        
                        #<p><h9>)+element.safe_content+hint_html+%Q(</h9>
                      
                        #)
                    elsif category=="image"
                        content_html=' <h2> <img src = '+element.safe_content+ ' /> </h2> '
                        # @item_html=@item_html+%Q(
                        
                        # <h2> <img src = )+element.safe_content+%Q( /> </h2>
                       
                        # )
                    elsif category=="video"
                        content_html='<h2> <iframe frameborder="0" width="480" height="360" src= '+element.safe_content+' > </iframe><br /></i> </h2> '
                        # @item_html=@item_html+%Q(
                      
                        # <h2> <iframe frameborder="0" width="480" height="360" src= )+element.safe_content+%Q( > </iframe><br /></i> </h2>
                        #                     )
                    end
                    @item_html=@item_html+'<td style="vertical-align:middle" > ' +content_html+' </td> <td style="vertical-align:middle"> <p align="right">'+hint_html+%Q(</p> 
                    </td> 
                    </tr>
                    )
                else
                    @item_html=@item_html+ 'No such element as '+item_string
                end
                    

            end
        end

        @item_html=@item_html+%Q(
        <table class="table">  
        <tbody>
        <tr>
        <td>
        )

        @item_html=@item_html+%Q(<input id="really" name="really" type="hidden" value="yes" />
        <input id="profile_id" name="profile_id" type="hidden" value=")+params[:profile_id]+ '" />' if params[:profile_id] 


        @item_html=@item_html+ %Q(
        <input type="submit" class="bobutton" value="Check answers" alt="Check Answers">
        </form>
        )

        


        #@item_html=@item_html+'Score: \(\frac{'+correct.to_s+'}{'+total.to_s+'}\)'
        @item_html=@item_html+'<h9><br> Current score: '+correct.to_s+'/'+total.to_s+ "</h9> </td>"

        if correct==total && total>0
            @item_html='<div> <table class="table"> <tbody <tr> <td> <img src = http://i970.photobucket.com/albums/ae189/gumboil/Goldstarnew.jpg width="150" height="90" /> </td> <td style="vertical-align:middle"> <p align="right"> <h9>Item solved</h9> </p> </td> </tr> </tbody> </table> </div>' + @item_html
            success_array=eval(current_user.item_successes)
            unless success_array.include?(@item.id)
                success_array << @item.id
            end
            
            current_user.update_attribute(:item_successes, success_array.to_s)
            
        elsif eval(current_user.item_successes).include?(@item.id)
            @item_html='<div> <table class="table"> <tbody <tr> <td> <img src = http://i970.photobucket.com/albums/ae189/gumboil/Greystar.jpg width="150" height="90" /> </td> <td style="vertical-align:middle"> <p align="right"> <h9>Item previously solved</h9> </p> </td> </tr> </tbody> </table> </div>' + @item_html
        end
        # unless correct==total 
        #     success_array=eval(current_user.item_successes)
        #     if success_array.include?(@item.id)
        #         success_array.delete(@item.id)
        #         current_user.update_attribute(:item_successes, success_array.to_s)
        #     end
        # end



        sign_in current_user

        @item_html=@item_html+ %Q(
            </tr>
            </tbody> 
            </table>
            )






    end

    def score(profile)
        return ["0/0","none.jpg",[]] if profile == nil
        content=eval(Course.find_by_id(profile.course).content)
        user=User.find_by_id(profile.user)
        return ["0/0","none.jpg",[]] if content == []
        successes=0
        total=0
        medals=[1,1,1]
        success_array=[]
        content.each do
            |stage|
            stagecode=''
            (0..2).each do
                |part|
                unless stage[part]==""
                    total=total+1
                    if eval(user.item_successes).include?(stage[part].to_i)
                        stagecode=stagecode+'T'
                        successes=successes+1
                    else
                        stagecode=stagecode+'F'
                        medals[part]=0
                    end
                else
                    stagecode=stagecode+'F'
                    medals[part]=0
                end
            end
            success_array<<stagecode
        end
        medal="none.jpg"
        
        medal="bronze.png" if medals[0]==1        
        medal="silver.png" if medals[1]==1 && medals[0]==1     
        medal="gold.png" if medals[2]==1 && medals[1]==1 && medals[0]==1

        return [successes.to_s+'/'+total.to_s,medal,success_array]
    end



  def abandon_item_build
    if session[:current_item_id]
      @item=Item.find_by_id(session[:current_item_id])

      if @item&&@item.update_attributes(params[:item])
          flash[:success] = "Stopped editing Item "+session[:current_item_id].to_s
        end
      session[:current_item_id] = nil
    end 
  end

  def abandon_course_build
    if session[:current_course_id]
      @course=Course.find_by_id(session[:current_course_id])  
      if @course.update_attributes(params[:course])
          flash[:success] = "Stopped editing Course "+session[:current_course_id].to_s
        end
      session[:current_course_id] = nil
    end 
  end

  def displaycourse(profile)
  end

  def displaycourses(user, coursearray)
  end
end