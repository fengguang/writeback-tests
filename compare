#!/usr/bin/ruby

require 'optparse'
require 'ostruct'

NFS_MNT="/fs/nfs"

$cfield = "kernel"
$cfield_hash = Hash.new
$cfield_array = Array.new
$cases = Hash.new
$sum = Array.new
$grep = //
$vgrep = /SOME IMPOSSIBLE PATTERN sdfghjkl:1234567890;/

$evaluate = "write_bw"

# these are available to the -e option
$cpu_vars = [ "user", "nice", "system", "iowait", "steal", "idle" ]
$io_vars = [ "dev", "rrqm_s", "wrqm_s", "r_s", "w_s", "rkB_s", "wkB_s", "avgrq_sz", "avgqu_sz", "await", "svctm", "util" ]
$nfs_vars = [ "nr_commits", "nr_writes", "write_total", "commit_size", "write_size", "write_queue_time", "write_rtt_time", "write_execute_time", "commit_queue_time", "commit_rtt_time", "commit_execute_time" ]

$perf_vars = [
  "cpu-cycles",
  "cycles",
  "stalled-cycles-frontend",
  "idle-cycles-frontend",
  "stalled-cycles-backend",
  "idle-cycles-backend",
  "instructions",
  "cache-references",
  "cache-misses",
  "branch-instructions",
  "branches",
  "branch-misses",
  "bus-cycles",
  "cpu-clock",
  "task-clock",
  "page-faults",
  "faults",
  "minor-faults",
  "major-faults",
  "context-switches",
  "cs",
  "cpu-migrations",
  "migrations",
  "alignment-faults",
  "emulation-faults",
  "L1-dcache-loads",
  "L1-dcache-load-misses",
  "L1-dcache-stores",
  "L1-dcache-store-misses",
  "L1-dcache-prefetches",
  "L1-dcache-prefetch-misses",
  "L1-icache-loads",
  "L1-icache-load-misses",
  "L1-icache-prefetches",
  "L1-icache-prefetch-misses",
  "LLC-loads",
  "LLC-load-misses",
  "LLC-stores",
  "LLC-store-misses",
  "LLC-prefetches",
  "LLC-prefetch-misses",
  "dTLB-loads",
  "dTLB-load-misses",
  "dTLB-stores",
  "dTLB-store-misses",
  "dTLB-prefetches",
  "dTLB-prefetch-misses",
  "iTLB-loads",
  "iTLB-load-misses",
  "branch-loads",
  "branch-load-misses",
  "node-loads",
  "node-load-misses",
  "node-stores",
  "node-store-misses",
  "node-prefetches",
  "node-prefetch-misses",
]

$nfs_nr_commits = 0
$nfs_nr_writes = 0

$nfs_write_total = 0
$nfs_commit_size = 0
$nfs_write_size = 0

$nfs_write_queue_time = 0
$nfs_write_rtt_time = 0
$nfs_write_execute_time = 0

$nfs_commit_queue_time = 0
$nfs_commit_rtt_time = 0
$nfs_commit_execute_time = 0

opts = OptionParser.new do |opts|
        opts.banner = "Usage: compare.rb [options] cases..."

        opts.separator ""
        opts.separator "options:"

        opts.on("-c FIELD", "--compare FIELD", "compare FIELD: fs/kernel/job/run") do |field|
                $cfield = field
		# puts "#{$cfield}\n"
        end

        opts.on("-e FIELD", "--evaluate FIELD", "evaluate FIELD: write_bw/nfs_*") do |field|
                $evaluate = field
        end

        opts.on("-g PATTERN", "--grep PATTERN", "only compare cases that match PATTERN") do |pattern|
                $grep = Regexp.new(pattern)
        end

        opts.on("-v PATTERN", "--reverse-grep PATTERN", "exclude cases that match PATTERN") do |pattern|
                $vgrep = Regexp.new(pattern)
        end

        opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
        end

end

opts.parse!(ARGV)

def iostat_cpu(path)
	file = "#{path}/iostat-cpu"
	eval "$#{$evaluate} = 0"
	vars = $cpu_vars
	vars.each { |var| eval "$cpu_#{var} = 0.0" }
	return if not File.exist?(file)
	stat = File.new(file).readlines
	stat.each_with_index do |line, i|
		next if i < 3
		vals = line.split
		vars.each_with_index { |var, i| eval "$cpu_#{var} += #{vals[i]}" }
	end
	vars.each { |var| eval "$cpu_#{var} /= #{stat.size-3}" }
end

def iostat_disk(path)
	file = "#{path}/iostat-disk"
	eval "$#{$evaluate} = 0"
	vars = $io_vars
	vars.each { |var| eval "$io_#{var} = 0.0" }
	return if not File.exist?(file)
	stat = File.new(file).readlines
	stat.each_with_index do |line, i|
		next if i < 3
		vals = line.split
		vars.each_with_index { |var, i| eval "$io_#{var} += #{vals[i]}" if i > 0}
	end
	vars.each { |var| eval "$io_#{var} /= #{stat.size-3}" }
end

def vmstat(path)
	file = "#{path}/vmstat-end"
	eval "$#{$evaluate} = 0"
	return if not File.exist?(file)

	stat = File.new(file).readlines
	stat.each do |line|
		var, val = line.split
		eval "$#{var} = #{val}"
	end
end

def nfs_stats(path)
	file = "#{path}/mountstats-end"

	$nfs_nr_commits = 0
	$nfs_nr_writes = 0

	$nfs_write_mb = 0
	$nfs_nr_commits_per_mb = 0
	$nfs_nr_writes_per_mb = 0

	$nfs_write_queue_time = 0
	$nfs_write_rtt_time = 0
	$nfs_write_execute_time = 0

	$nfs_commit_queue_time = 0
	$nfs_commit_rtt_time = 0
	$nfs_commit_execute_time = 0

	return if not File.exist?(file)

	stat = File.new(file).readlines
	nfsmnt = nil
	stat.each do |line|
		if line.index("mounted on /")
			nfsmnt = line.index("mounted on #{NFS_MNT}")
		end
		next unless nfsmnt
		if line.index("WRITE: ")
			n = line.split
			$nfs_nr_writes = n[1].to_i
			next if $nfs_nr_writes == 0
			$nfs_write_total = n[4].to_f
			$nfs_write_size = $nfs_write_total / $nfs_nr_writes / (1<<20)
			$nfs_write_queue_time   = n[6].to_f / $nfs_nr_writes
			$nfs_write_rtt_time     = n[7].to_f / $nfs_nr_writes
			$nfs_write_execute_time = n[8].to_f / $nfs_nr_writes
			# puts line
			# puts $nfs_nr_writes
		end
		if line.index("COMMIT: ")
			n = line.split
			$nfs_nr_commits = n[1].to_i
			next if $nfs_nr_commits == 0
			$nfs_commit_size = $nfs_write_total / $nfs_nr_commits / (1<<20)
			$nfs_commit_queue_time   = n[6].to_f / $nfs_nr_commits
			$nfs_commit_rtt_time     = n[7].to_f / $nfs_nr_commits
			$nfs_commit_execute_time = n[8].to_f / $nfs_nr_commits
		end
	end
end

def is_perf_event(name)
	return true if name.index(":")
	return true if $perf_vars.index(name)
	return false
end

def perf_stats(path)
	$perf_event = {}
	file = "#{path}/perf-stat"
	return if not File.exist?(file)

	stat = File.new(file).readlines
	stat.each do |line|
		v, e = line.split("\t")
		e.chomp!
		$perf_event[e] = v.to_i
		# printf "#{e}=#{v}\n"
	end
end

def write_bw(path)
	cache = "#{path}/write-bandwidth"
	if File.exist?(cache)
		cached_bw = File.new(cache).readlines
		return cached_bw[0].to_f
	end
	bw = 0 # MB/s
	file = "#{path}/trace-global_dirty_state-flusher"
	if File.exist?(file)
		state = File.new(file).readlines
		n = [state.size / 10, 100].min
		return 0 if n == 0
		time0, dirty, writeback, unstable, bg_thresh, thresh, limit, dirtied, written0 = state[0].split
		time, dirty, writeback, unstable, bg_thresh, thresh, limit, dirtied, written = state[-n].split
		bw = (written.to_i - written0.to_i) / (time.to_f - time0.to_f) / 256
		File.open(cache, "w") { |f| f.puts "#{bw}" }
	end
	return bw
end

def add_dd(path)
	if $evaluate == "write_bw"
		bw = write_bw(path)
		# puts path, bw
		return if bw == 0
	elsif $evaluate.index("nfs_") == 0
		nfs_stats(path)
		eval "bw = $#{$evaluate}"
	elsif $evaluate.index("cpu_") == 0
		iostat_cpu(path)
		eval "bw = $#{$evaluate}"
	elsif $evaluate.index("io_") == 0
		iostat_disk(path)
		eval "bw = $#{$evaluate}"
	elsif is_perf_event($evaluate)
		perf_stats(path)
		bw = $perf_event[$evaluate]
	else
		vmstat(path)
		eval "bw = $#{$evaluate}"
	end
	prefix = ""
	if path =~ /(.*\/)(.*)/
		prefix = $1
		path = $2
	end
	# nfs-10dd-1M-1p-32069M-20:10-3.1.0-rc4+
	path =~ /([a-z0-9:=]+)-([0-9]+dd[:=a-zA-Z0-9]*)-([0-9]+)-(.*)/;
	all, fs, job, run, kernel = *$~
	if ! kernel
		path =~ /([a-z0-9:=]+)-(fio_[a-z_0-9]+)-([0-9]+)-(.*)/;
		all, fs, job, run, kernel = *$~
	end
	ckey = ""

	eval "ckey = #{$cfield};"
	if ckey and !$cfield_hash.has_key?(ckey)
		$cfield_array.push(ckey)
		$cfield_hash[ckey] = 1
		$sum.push 0.0
	end
	eval "#{$cfield} = $cfield_array[0]"
	# bs="4k"
	key = "#{prefix}#{fs}-#{job}-#{run}-#{kernel}"
	if !$cases.has_key?(key)
		$cases[key] = { ckey => bw }
	else
		$cases[key][ckey] = bw
	end
	# print "#{fs}-#{job}-#{run}-#{kernel}-#{bw}\n"
end

ARGV.each { |path|
	if path =~ $grep and not path =~ $vgrep
		add_dd path
	end
}

$cfield_array.each { |ckey|
	printf "%24s  ", ckey
}
puts
$cfield_array.each {
	printf "------------------------  "
}
puts
$cases.sort.each { |key, value|
	n = 0
	$cfield_hash.each_key { |ckey|
		n += 1 if $cases[key][ckey]
	}
	next if n < 2
	$cfield_array.each_index { |i|
		ckey = $cfield_array[i]
		bw = $cases[key][ckey] || 0
		bw0 = $cases[key][$cfield_array[0]] || 0
		if i == 0 || bw == 0 || bw0 == 0
			printf "%24.2f  ", bw
		else
			printf "%+10.1f%% %12.2f  ", 100.0 * (bw - bw0) / bw0, bw
		end
		$sum[i] += bw
	}
	printf "%s\n", key
}

bw0 = $sum[0]
$sum.each_with_index { |bw, i|
	if i == 0 || bw0 == 0
		printf "%24.2f  ", bw
	else
		printf "%+10.1f%% %12.2f  ", 100.0 * (bw - bw0) / bw0, bw
	end
}
puts "TOTAL #{$evaluate}"
