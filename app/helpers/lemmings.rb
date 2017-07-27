## matching algorithm


## data is two sets of nodes and a hash showing the edges, e.g.
# leftset = (0..3).to_a
# rightset = (0..3).to_a
# g = {[1,0]=>true, [1,2]=>true, [1,3]=>true, [2,0]=>true, [3,1]=>true, [0,1]=>true, [0,2]=>true, [2,3]=>true}
## end of sample data
def matching(g, leftset, rightset)

    m_left = []

    m_right = []

    nl = leftset.size
    nr = rightset.size
    unmatched_l = leftset.clone
    unmatched_r = rightset.clone


    ## greedily choose an initial matching
    i=0
    g1 = g.clone
    match = {}
    while i < nl
        j=0
        while j < nr
            if g1[[i,j]]
                match[i] = j
                g1.delete_if {|key,value| key[0]==i || key[1]==j}
                unmatched_l.delete(i)
                unmatched_r.delete(j)
                j = nr
            else
                j += 1
            end
        end
        i += 1
    end
    #
    puts "initial matching #{match.to_s} unmatched_l=#{unmatched_l} unmatched_r=#{unmatched_r}"

    g1 = g.clone

    while unmatched_l.count > 0 && unmatched_r.count > 0
        path = false
        lset=[[unmatched_l[0]]]
        rset=[]
        visited_r = []
        endpoint = nil
        i = 0
        while !path && unmatched_l.count > 0
            # find an alternating path from 1st elt of unmatched_l if poss

            #puts "trying a path from #{unmatched_l[0]}"
            rset << ((g.select {|key, value| lset[i].include?(key[0]) && !visited_r.include?(key[1])}).keys).map {|n| n[1]}
            #puts "rset = #{rset.to_s}"
            if rset[-1].size == 0
                path = "no"
            elsif (rset[-1] & unmatched_r).size > 0
                path = "yes"
                endpoint = (rset[-1] & unmatched_r)[0]
                #puts "hooray - can end at #{endpoint}"
            else
                i += 1
                #puts "finding the x's matched to #{rset[-1].to_s} #{rset[-1].map {|n| n[1]}}"
                lset << [(match.select {|key, value| rset[-1].include?(value)})].map {|item| item.keys}.flatten
                visited_r += rset[-1]
                #puts "visited #{visited_r} lset = #{lset.to_s}"
            end
            if path == "no"
                # if there isn't a path, delete this l - element and try again    
                unmatched_l.delete_at(0)
                path = false
                lset=[[unmatched_l[0]]]
                rset=[]
                visited_r = []
                endpoint = nil
                i = 0
            end
        end

        y = endpoint

        if y
            route = []
            i.downto(0) do |j|
                x = (lset[j].select {|x| g[[x,y]]})[0]
                route << [x,y]
                y = match[x]
            end
            route.each_index do |index|
                match[route[index][0]] = route[index][1]
            end

            unmatched_l.delete_at(0)
            unmatched_r.delete(y)
        end
    end
    return match
end





leftset = (0..4).to_a
rightset = (0..4).to_a
g = {[1, 0]=>true, [2, 0]=>true, [2, 1]=>true, [3, 0]=>true, [3, 1]=>true, [2, 4]=>true}
    
puts "maximal matching #{matching(g, leftset, rightset).to_s}"
            


def adj(i,j,char,r,c)
    istep = 0
    jstep = 0
    istep = 1 unless char == "|"
    jstep = 1 unless char == "-"
    jstep = -1 if char == "/"
    newi1 = (i + istep) % r
    newi2 = (i - istep) % r
    newj1 = (j + jstep) % c
    newj2 = (j - jstep) % c
    return [r * newi1 + newj1,r * newi2 + newj2]
end






infile = File.new("input.txt")
outfile = File.new("output.txt","w")


t = infile.gets.to_i


t.times do |case_number|
    r,c = infile.gets.strip.split(" ").map {|x| x.to_i}
    lset = [0..rc-1].to_a
    rset = [0..rc-1].to_a
    edge = {}
    g = {}
    r.times do |i|
        row = infile.gets.strip.split("")
        row.count.times do |j|
            pos = r*i + j
            x,y = adj(i,j,row[j],r,c)
            edge[pos] = [x,y]
            g[pos,x] = g[pos,y] = true
        end
    end
    puts "#{edge}"
    puts "#{g}"



    

    #outfile.puts "Case ##{case_number + 1}: #{answer}"
end

    

infile.close
outfile.close