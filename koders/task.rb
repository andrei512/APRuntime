class Task	
	attr_accessor :key, :charge, :process, :kode, :subtasks

	def initialize
		charge = []
		process = []
		kode = []
	end

	def << action
		if type = action[:type] 
			if type == :charge
				charge << action
			elsif type == :process
				process << action
			elsif type == :kode
				kode << action
			elsif type == :subtask 
				subtasks << action
			end
		end
	end

	def run context = {}
		# run subtasks first
		subtasks.each do |task|
			ctx = task[:context] || context
			task[]
		end

		# charge required resources
		charge.each do |charge_task|
			perform(charge_process, context)
		end

		# process resources
		process.each do |process_task|
			perform(charge_process, context)
		end

		# kode !
		kode.each do |kode_task|
			perform(kode_task, context)
		end
	end

	def perform action, context
		if [:charge, :process, :kode].include? action[:type]
			action[:lambda].call(action, context) if action[:lambda]
		end
	end

	def self.charge lambda, context = {}
		{
			type: :charge,
			lambda: lambda,
			context: context
		}
	end

	def self.process lambda, context = {}
		{
			type: :process,
			lambda: lambda,
			context: context
		}
	end

	def self.kode lambda, context = {}
		{
			type: :kode,
			lambda: lambda,
			context: context
		}
	end

	def self.subtask task, context = {}
		{
			type: :subtask,
			task: task,
			context: context
		}
	end
end

puts Task.charge(lambda {
	puts "Hello world! - charge"
})

puts Task.process(lambda {
	puts "Hello world! - process"
})

puts Task.kode(lambda {
	puts "Hello world! - kode"
})

puts Task.subtask(Task.new)

__END__

Process.createFile("foo.txt")

Process.createFilesFromList(["foo.txt", "bar.txt"])

Process.appendStringToFile("ana are mere.", "foo.txt")


