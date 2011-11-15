#!/usr/bin/ruby

def print_line(name, line)
	printf("%s\t", name)
	line.each {|i|
		printf("%10.3f ", i)
	}
	puts ""
end

def print_matrix(matrix)
	if matrix.size == 0
		return
	end

	cols = matrix[0].size
	min = Array.new(cols, 2**31)
	max = Array.new(cols, -2**31)
	sum = Array.new(cols, 0)
	std = Array.new(cols, 0)
	avg = []
	row = 0
	matrix.each { |line|
		col = 0
		line.each { |i|
			sum[col] += i
			std[col] += i*i
			if max[col] < i
				max[col] = i
			end
			if min[col] > i
				min[col] = i
			end
			col += 1
		}
		row += 1
		# print_line(row, line)
	}
	sum.each {|i| avg << i/row}
	std.each_index {|i|
		std[i] = (std[i] / row) - avg[i] * avg[i];
		std[i] = std[i] > 0 ? Math::sqrt(std[i]) : 0
	}
	# [[ $0 == "sum" ]] && print_line("sum", sum)
	# [[ $0 == "avg" ]] && print_line("avg", avg)
	print_line("sum", sum)
	print_line("avg", avg)
	print_line("stddev", std)
	# print_line("min", min)
	# print_line("max", max)
	puts
end


prev_cols = 0
cols = 0
matrix = []

STDIN.each_line { |l|
	line = []
	l = ' ' + l
	l.scan(/\s-?\d*\.?\d+/) { |wd|
		d = wd[1..-1].to_f
		line << d
	}

	if line.size == cols and cols > 0
		matrix << line
	else
		print_matrix matrix if matrix.size > 1
		if line.size > 0
			matrix = [line]
			cols = line.size
		else
			matrix = []
			cols = 0
		end
	end

	prev_cols = line.size
}

print_matrix matrix if matrix.size > 0
