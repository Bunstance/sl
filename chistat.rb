
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
		
		return pearson(a,b)

    end


    def pmcccrit(string)
        list = arglist(string)
        dof = list[0].to_i
        ppair = list[2].split("/").map(&:to_i)
        prob = ppair[0].to_r/ppair[1]
        str = "#{[dof,prob]}"
        p str
        pmcchash =  {"4, (1/10)"=>0.8, "4, (1/20)"=>0.9, "4, (1/40)"=>0.95, "4, (1/100)"=>0.98, "4, (1/200)"=>0.99, "5, (1/10)"=>0.687, "5, (1/20)"=>0.8054, "5, (1/40)"=>0.8783, "5, (1/100)"=>0.9343, "5, (1/200)"=>0.9587, "6, (1/10)"=>0.6084, "6, (1/20)"=>0.7293, "6, (1/40)"=>0.8114, "6, (1/100)"=>0.8822, "6, (1/200)"=>0.9172, "7, (1/10)"=>0.5509, "7, (1/20)"=>0.6694, "7, (1/40)"=>0.7545, "7, (1/100)"=>0.8329, "7, (1/200)"=>0.8745, "8, (1/10)"=>0.5067, "8, (1/20)"=>0.6215, "8, (1/40)"=>0.7067, "8, (1/100)"=>0.7887, "8, (1/200)"=>0.8343, "9, (1/10)"=>0.4716, "9, (1/20)"=>0.5822, "9, (1/40)"=>0.6664, "9, (1/100)"=>0.7498, "9, (1/200)"=>0.7977, "10, (1/10)"=>0.4428, "10, (1/20)"=>0.5494, "10, (1/40)"=>0.6319, "10, (1/100)"=>0.7155, "10, (1/200)"=>0.7646, "11, (1/10)"=>0.4187, "11, (1/20)"=>0.5214, "11, (1/40)"=>0.6021, "11, (1/100)"=>0.6851, "11, (1/200)"=>0.7348, "12, (1/10)"=>0.3981, "12, (1/20)"=>0.4973, "12, (1/40)"=>0.576, "12, (1/100)"=>0.6581, "12, (1/200)"=>0.7079, "13, (1/10)"=>0.3802, "13, (1/20)"=>0.4762, "13, (1/40)"=>0.5529, "13, (1/100)"=>0.6339, "13, (1/200)"=>0.6835, "14, (1/10)"=>0.3646, "14, (1/20)"=>0.4575, "14, (1/40)"=>0.5324, "14, (1/100)"=>0.612, "14, (1/200)"=>0.6614, "15, (1/10)"=>0.3507, "15, (1/20)"=>0.4409, "15, (1/40)"=>0.514, "15, (1/100)"=>0.5923, "15, (1/200)"=>0.6411, "16, (1/10)"=>0.3383, "16, (1/20)"=>0.4259, "16, (1/40)"=>0.4973, "16, (1/100)"=>0.5742, "16, (1/200)"=>0.6226, "17, (1/10)"=>0.3271, "17, (1/20)"=>0.4124, "17, (1/40)"=>0.4821, "17, (1/100)"=>0.5577, "17, (1/200)"=>0.6055, "18, (1/10)"=>0.317, "18, (1/20)"=>0.4, "18, (1/40)"=>0.4683, "18, (1/100)"=>0.5425, "18, (1/200)"=>0.5897, "19, (1/10)"=>0.3077, "19, (1/20)"=>0.3887, "19, (1/40)"=>0.4555, "19, (1/100)"=>0.5285, "19, (1/200)"=>0.5751, "20, (1/10)"=>0.2992, "20, (1/20)"=>0.3783, "20, (1/40)"=>0.4438, "20, (1/100)"=>0.5155, "20, (1/200)"=>0.5614, "21, (1/10)"=>0.2914, "21, (1/20)"=>0.3687, "21, (1/40)"=>0.4329, "21, (1/100)"=>0.5034, "21, (1/200)"=>0.5487, "22, (1/10)"=>0.2841, "22, (1/20)"=>0.3598, "22, (1/40)"=>0.4227, "22, (1/100)"=>0.4921, "22, (1/200)"=>0.5368, "23, (1/10)"=>0.2774, "23, (1/20)"=>0.3515, "23, (1/40)"=>0.4132, "23, (1/100)"=>0.4815, "23, (1/200)"=>0.5256, "24, (1/10)"=>0.2711, "24, (1/20)"=>0.3438, "24, (1/40)"=>0.4044, "24, (1/100)"=>0.4716, "24, (1/200)"=>0.5151, "25, (1/10)"=>0.2653, "25, (1/20)"=>0.3365, "25, (1/40)"=>0.3961, "25, (1/100)"=>0.4622, "25, (1/200)"=>0.5052, "26, (1/10)"=>0.2598, "26, (1/20)"=>0.3297, "26, (1/40)"=>0.3882, "26, (1/100)"=>0.4534, "26, (1/200)"=>0.4958, "27, (1/10)"=>0.2546, "27, (1/20)"=>0.3233, "27, (1/40)"=>0.3809, "27, (1/100)"=>0.4451, "27, (1/200)"=>0.4869, "28, (1/10)"=>0.2497, "28, (1/20)"=>0.3172, "28, (1/40)"=>0.3739, "28, (1/100)"=>0.4372, "28, (1/200)"=>0.4785, "29, (1/10)"=>0.2451, "29, (1/20)"=>0.3115, "29, (1/40)"=>0.3673, "29, (1/100)"=>0.4297, "29, (1/200)"=>0.4705, "30, (1/10)"=>0.2407, "30, (1/20)"=>0.3061, "30, (1/40)"=>0.361, "30, (1/100)"=>0.4226, "30, (1/200)"=>0.4629, "31, (1/10)"=>0.2366, "31, (1/20)"=>0.3009, "31, (1/40)"=>0.355, "31, (1/100)"=>0.4158, "31, (1/200)"=>0.4556, "32, (1/10)"=>0.2327, "32, (1/20)"=>0.296, "32, (1/40)"=>0.3494, "32, (1/100)"=>0.4093, "32, (1/200)"=>0.4487, "33, (1/10)"=>0.2289, "33, (1/20)"=>0.2913, "33, (1/40)"=>0.344, "33, (1/100)"=>0.4032, "33, (1/200)"=>0.4421, "34, (1/10)"=>0.2254, "34, (1/20)"=>0.2869, "34, (1/40)"=>0.3388, "34, (1/100)"=>0.3972, "34, (1/200)"=>0.4357, "35, (1/10)"=>0.222, "35, (1/20)"=>0.2826, "35, (1/40)"=>0.3338, "35, (1/100)"=>0.3916, "35, (1/200)"=>0.4296, "36, (1/10)"=>0.2187, "36, (1/20)"=>0.2785, "36, (1/40)"=>0.3291, "36, (1/100)"=>0.3862, "36, (1/200)"=>0.4238, "37, (1/10)"=>0.2156, "37, (1/20)"=>0.2746, "37, (1/40)"=>0.3246, "37, (1/100)"=>0.381, "37, (1/200)"=>0.4182, "38, (1/10)"=>0.2126, "38, (1/20)"=>0.2709, "38, (1/40)"=>0.3202, "38, (1/100)"=>0.376, "38, (1/200)"=>0.4128, "39, (1/10)"=>0.2097, "39, (1/20)"=>0.2673, "39, (1/40)"=>0.316, "39, (1/100)"=>0.3712, "39, (1/200)"=>0.4076, "40, (1/10)"=>0.207, "40, (1/20)"=>0.2638, "40, (1/40)"=>0.312, "40, (1/100)"=>0.3665, "40, (1/200)"=>0.4026, "41, (1/10)"=>0.2043, "41, (1/20)"=>0.2605, "41, (1/40)"=>0.3081, "41, (1/100)"=>0.3621, "41, (1/200)"=>0.3978, "42, (1/10)"=>0.2018, "42, (1/20)"=>0.2573, "42, (1/40)"=>0.3044, "42, (1/100)"=>0.3578, "42, (1/200)"=>0.3932, "43, (1/10)"=>0.1993, "43, (1/20)"=>0.2542, "43, (1/40)"=>0.3008, "43, (1/100)"=>0.3536, "43, (1/200)"=>0.3887, "44, (1/10)"=>0.197, "44, (1/20)"=>0.2512, "44, (1/40)"=>0.2973, "44, (1/100)"=>0.3496, "44, (1/200)"=>0.3843, "45, (1/10)"=>0.1947, "45, (1/20)"=>0.2483, "45, (1/40)"=>0.294, "45, (1/100)"=>0.3457, "45, (1/200)"=>0.3801, "46, (1/10)"=>0.1925, "46, (1/20)"=>0.2455, "46, (1/40)"=>0.2907, "46, (1/100)"=>0.342, "46, (1/200)"=>0.3761, "47, (1/10)"=>0.1903, "47, (1/20)"=>0.2429, "47, (1/40)"=>0.2876, "47, (1/100)"=>0.3384, "47, (1/200)"=>0.3721, "48, (1/10)"=>0.1883, "48, (1/20)"=>0.2403, "48, (1/40)"=>0.2845, "48, (1/100)"=>0.3348, "48, (1/200)"=>0.3683, "49, (1/10)"=>0.1863, "49, (1/20)"=>0.2377, "49, (1/40)"=>0.2816, "49, (1/100)"=>0.3314, "49, (1/200)"=>0.3646, "50, (1/10)"=>0.1843, "50, (1/20)"=>0.2353, "50, (1/40)"=>0.2787, "50, (1/100)"=>0.3281, "50, (1/200)"=>0.361, "60, (1/10)"=>0.1678, "60, (1/20)"=>0.2144, "60, (1/40)"=>0.2542, "60, (1/100)"=>0.2997, "60, (1/200)"=>0.3301, "70, (1/10)"=>0.155, "70, (1/20)"=>0.1982, "70, (1/40)"=>0.2352, "70, (1/100)"=>0.2776, "70, (1/200)"=>0.306, "80, (1/10)"=>0.1448, "80, (1/20)"=>0.1852, "80, (1/40)"=>0.2199, "80, (1/100)"=>0.2597, "80, (1/200)"=>0.2864, "90, (1/10)"=>0.1364, "90, (1/20)"=>0.1745, "90, (1/40)"=>0.2072, "90, (1/100)"=>0.2449, "90, (1/200)"=>0.2702, "100, (1/10)"=>0.1292, "100, (1/20)"=>0.1654, "100, (1/40)"=>0.1966, "100, (1/100)"=>0.2324, "100, (1/200)"=>0.2565}
		return pmcchash[str[1..-2]]
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



puts spearman("<20/1>,<20/1>,<13/1>|<10/1>,<19/1>,<18/1>").to_f
puts pmcc("<5/2>,<5/2/1>,<1/1>|<1/1>,<3/1>,<2/1>").to_f
puts pearson([2.5, 1.0, 2.5] , [1.0, 2.0, 3.0])
puts pearson([27,15,19,17,31,13,17,21] , [51,35,38,29,62,29,18,39]).to_f
p pmcccrit("<7/1>,<1/40>")

