require File.dirname(__FILE__) + '/task.rb'

class Koder 
	attr_accessor :hash

	def self.koder_with hash
		koder = Koder.new
		koder.hash = hash
		return koder
	end	

	def load data, key = "root"
		input = hash.keys.filter { |key|
			key["input"]
		}.map { |key|
			hash[key]
		}

		puts input
	end

	def process
		output = hash.keys.filter { |key|
			key["output"]
		}.map { |key|
			hash[key]
		}
	end

	def kode
		output = hash.keys.filter { |key|
			key["output"]
		}.map { |key|
			hash[key]
		}

		puts output
	end

	def << arg
		if arg.is_a? Hash
			puts arg
		end
	end

end

# koder = Koder.koder_with({})

# puts koder

# koder << {}