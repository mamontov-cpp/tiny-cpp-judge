require 'open3'

@timelimit = 30
@memorylimit = 256

def get_memory(pid)
	stdin, stdout, stderr, wait_thr = Open3.popen3("getmem.exe " + pid.to_s)
	val = stdout.read.to_i
	wait_thr.join
	stdin.close
	stdout.close
	stderr.close
	return val
end

def run_one_test(executable, sourcefile, resultfile)
	sfile = File.open(sourcefile, "rb");
	inputtest = sfile.read
	
	sfile = File.open(resultfile, "rb");
	resulttest = sfile.read
	
	stdin, stdout, stderr, wait_thr = Open3.popen3(executable)
	begin
		stdin.write(inputtest)
		thread = wait_thr.join(@timelimit);
		result = ""
	rescue Errno::EPIPE
		result = "[FAIL] Segmentation fault while reading stdin!"
		return result
	end
	
	if (thread.nil?)
		Process.kill("KILL", wait_thr[:pid])
		wait_thr.terminate()
		result = "[FAIL] Timeout: reached limit of " + @timelimit.to_s + " seconds"
	else		
		# TODO: Here is segmentation fault must be handled - dunno why 5 here
		if (wait_thr.value.exitstatus == 5);
			result = "[FAIL] Segmentation fault!"
		end
		mem_usage = get_memory(wait_thr[:pid])
		if (mem_usage > @memorylimit)
			result = "[FAIL] Out of memory " + mem_usage.to_s + " used"
		else
			data = stdout.read
			data = data.strip
			data.gsub!("\r\n", "\n")
			resulttest.gsub!("\r\n", "\n")
			data = data.split("\n").map(&:strip).join("\n")
			resulttest = resulttest.split("\n").map(&:strip).join("\n")
			ok = data == resulttest
			if ((resulttest.end_with? "\n") && !ok)
				resulttest = resulttest.slice(0, resulttest.length - 1)
				ok = data == resulttest
			end
			#print "Student: "
			#print data
			#print "|\n"
			#print "Resulttest: "
			#print resulttest
			#print "|\n"
			if (data == resulttest)
				result = "[OK]"
			else
				result = "[FAIL] Result mismatch"
			end
		end
	end
	stdin.close
	stdout.close
	stderr.close
	return result
end


def try_compile_executable(source)
	begin
		File.delete("a.exe")
	rescue Errno::ENOENT
		
	end
	stdin, stdout, stderr, wait_thr = Open3.popen3("g++ " +  source)
	pid = wait_thr[:pid]  # pid of the started process.
	compilationresult = stderr.read
	stdin.close
	stdout.close
	stderr.close
	if (wait_thr.value.exitstatus != 0)
		return compilationresult
	end	
	return nil
end

@task_grades = {"1" => 1.0, "2" => 1.0, "3" => 2.0, "4" => 2.0, "5" => 3.0, "6" => 4.0, "7" => 2.0}

if ARGV.length == 0
	print "Usage:  ruby tester.rb source task\n"
	print "source - name of source file, like 1.cpp\n"
	print "task  - name of folder with tests [1-4]\n"
else
	source = ARGV[0]
	task = ARGV[1]
	result = Dir.glob(task + "/*").select{|x| x.match(/^[^.]+$/)}
	elementcount = result.length 
	compilationerrors =  try_compile_executable(source)
	if compilationerrors.nil?
		pool = result.map{ 
			|name| 
			Thread.new(name) do |testname|
				Thread.current[:name] = testname
				Thread.current[:result] = run_one_test("a.exe", testname, testname + ".a")
			end
		}
		success = 0.0
		for thread in pool
			thread.join
			print thread[:name] + ": " + thread[:result] + "\n"
			if thread[:result] == "[OK]"
				success += 1.0
			end
		end
		grade = (success / result.length) * 100 # * @task_grades[task] * 100
		print "\nOverall grade: " + grade.to_s
	else
		print "Compilation failed\n"
		print compilationerrors
		print "\nOverall grade: 0\n"
	end
end
