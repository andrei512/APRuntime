require 'json'
require 'erb'
require 'FileUtils'

#!! CONSTANTS

# WEB for the web API and MA for Mobile Api
CLASS_PREFIX = "MA"



# used map from general types to Objective-C types
TYPE_HASH = {
	"Array" => "NSArray",
	"Str" => "NSString",
	"Int" => "NSNumber",
	"Num" => "NSNumber",
	"Object" => "NSDictionary",
	"Bool" => "NSNumber",
	"Date" => "NSDate",
	"Enum" => "NSString",
	"Value" => "NSObject",
	"HashRef" => "NSDictionary",
	"ArrayRef" => "NSArray"
}


#!! CLASS EXTENSIONS

class Hash
	def print_keys
		keys.each do |key|
			puts key
		end
	end
end

#!! HELPERS

def is_primitive? type
	if TYPE_HASH[type] != nil or TYPE_HASH.invert[type] != nil
		return true
	else
		return false
	end
end

def pretty_print object 
	puts JSON.pretty_generate object
end

# converts from name::space to CamelCase
# or from snake_case to CamenCase
def objective_class_name namespace_name	
	if namespace_name.scan(/::/).count > 0
		namespace_name.split("::").map { |word|
			if word.scan(/[A-Z]/).count > 0
				word
			else
				word.capitalize
			end
		}.join
	elsif namespace_name.scan(/_/).count > 0
		namespace_name.split("_").map { |w|
			w.capitalize
		}.join
	elsif namespace_name[0].scan(/[A-Z]/).count > 0
		namespace_name
	else
		namespace_name.capitalize
	end
end

# converts from snake_case to camelCase
def objective_name snake_name
	snake_name.split("_").reduce("") { |result, part|  
		if result != ""
			result + part.capitalize
		else
			part
		end
	}
end

def tabspaces indent_level
	return "    " * indent_level
end

def to_objc object, indent_level = 0, ignore_first = false
	first_indent = ignore_first ? "" : tabspaces(indent_level)
	indent = tabspaces indent_level
	if object.is_a? Array
		return "#{first_indent}@[\n" + 
				
				object.map { |item| 
					to_objc(item, indent_level + 1) 
				}.join(",\n") + 

				"\n" + 
				
				"#{indent}]"
	elsif object.is_a? Hash
		return "#{first_indent}@{\n" + 

				object.keys.map { |key| 
					"#{tabspaces(indent_level + 1)}#{to_objc(key)} : #{to_objc(object[key], indent_level + 1, true)}" 
				}.join(",\n") + 

				"\n" + 

				"#{indent}}"
	elsif object.is_a? String
		string = object
		string = string.gsub("\n", "\\n")
		string = string.gsub("\"", "\\\"")
		return "#{first_indent}@\"#{string}\""
	elsif object == nil
		return "#{first_indent}[NSNull null]"
	else
		return "#{first_indent}@(#{object})"
	end			
end

# string timestamp for sources
def timestamp 
	time = Time.new
	"#{time.day}/#{time.month}/#{time.year}"
end

# splits a long comment into multiple lines
def pretty_comment comment
	if comment == nil or comment.length == 0
		return ""
	end

	begin
		line_width = 100

		words = comment.scan(/\w+|\n/)
		lines = []
		line = ""
		words.each do |word|
			if word == "\n"
				lines << line
				line = ""
			else
				if line.length + word.length > line_width
					lines << line
					line = ""
				end

				if line.length == 0
					line = word
				else
					line = line + " " + word
				end
			end
		end
		if line.length > 0
			lines << line				
		end
		lines.map { |line|  
			"//  #{line}"
		}.join("\n")
	rescue Exception => e
		comment
	end
end

# a method for finding template file, also raises exeption if the template is not found
def template_named template_name
	template_path = "templates/#{template_name}.erb"
	if File.exists? template_path
		ERB.new(File.open(template_path).read)
	else
		raise "Template named '#{template_name}' not found at location #{template_path}!"
	end
end

def create_folders_for_path filepath
	directory_path = filepath.split(/\//)[0..-2].join("/")	
	FileUtils.mkdir_p(directory_path) unless File.exists?(directory_path)
end

@number_of_files = 0

def save_to_file text, filepath
	@number_of_files = @number_of_files + 1

	filepath = "output/" + filepath

	# make sure all folders are there
	create_folders_for_path filepath

	# write file
	File.open(filepath, "w") do |file|
		file.write(text)
	end	
end

def render template, b
	template.result(b)
end

#!! PARSE METADATA

# read metadatafile and deserialize it
METADATA = JSON.parse(File.open('metadata.json').read)	

# extract basic structures
ENUMS = METADATA["enums"] || {}
MODELS = METADATA["models"] || {}
SERVICES = METADATA["services"] || {}

#!! GENRATION METHODS

def header_for_file filename
	@header_template ||= template_named "header"
	render @header_template, binding
end

def generate_model model_info
	# load model templates 
	@model_interface_template ||= template_named "model.h" 
	@model_implementation_template ||= template_named "model.m"

	# create template context
	namespace_name = model_info[:namespace_name]
	name = model_info[:name]
	properties = model_info[:properties]	
	classes_to_import = model_info[:classes_to_import]

	# paths for model files and directories
	directory_path = "Models/#{namespace_name.split("::").join("/")}"
	interface_path = "#{directory_path}/#{name}.h"
	implementation_path = "#{directory_path}/#{name}.m"

	# begin task
	print "writing model #{name} ."


	# render code from template and save in output folder
	interface_code = render @model_interface_template, binding
	save_to_file interface_code, interface_path

	# progress
	print "."

	# render code from template and save in output folder
	implementation_code = render @model_implementation_template, binding
	save_to_file implementation_code, implementation_path

	# end task
	print ".\n"	
end


def generate_request request_info 
	@request_interface_template ||= template_named "request.h"
	@request_implementation_template ||= template_named "request.m"

	# create template context
	service_name = request_info[:service_name]
	service_path = request_info[:service_path]
	method_path = request_info[:method_path]
	method = request_info[:method]
	request_class = request_info[:request_class]
	request_input = request_info[:request_input]
	request_output = request_info[:request_output]
	request_documentation = request_info[:request_documentation]
	service = service_name.gsub("Service", "").gsub(CLASS_PREFIX, "")

	# begin task
	print "writing request #{request_class} ."

	# filepaths
	directory_path = "Services/#{service}/Requests/#{objective_class_name method_path}"
	interface_path = "#{directory_path}/#{request_class}.h"
	implementation_path = "#{directory_path}/#{request_class}.m"

	# render code from template and save in output folder
	interface_code = render @request_interface_template, binding
	save_to_file interface_code, interface_path

	# progress
	print "."

	# render code from template and save in output folder
	implementation_code = render @request_implementation_template, binding
	save_to_file implementation_code, implementation_path

	# end task
	print ".\n"	
end

def generate_service service_info
	@service_interface_template ||= template_named "service.h"
	@service_implementation_template ||= template_named "service.m"

	# create template context
	service_name = service_info[:service_name]
	requests = service_info[:requests]
	service = service_name.gsub("Service", "").gsub(CLASS_PREFIX, "")

	extra_data = ENUMS[service + "ExtraData"]
	searchable_columns = ENUMS[service + "SearchableColumns"]
	api_config = CLASS_PREFIX + "APIConfig"

	if searchable_columns
		searchable_columns.map! { |column|
			{
				macro:	"k_" + column.split(".").join("__"),
				original: column
			}
		} if searchable_columns
	end

	# begin task
	print "writing service #{service_name} ."

	# filepaths
	directory_path = "Services/#{service}"
	interface_path = "#{directory_path}/#{service_name}.h"
	implementation_path = "#{directory_path}/#{service_name}.m"

	# render code from template and save in output folder
	interface_code = render @service_interface_template, binding
	save_to_file interface_code, interface_path

	# progress
	print "."

	# render code from template and save in output folder
	implementation_code = render @service_implementation_template, binding
	save_to_file implementation_code, implementation_path

	# end task
	print ".\n"	
end

def generate_models
	model_classes = []

	# generate models
	MODELS.keys.each do |model_name|
		model_info = MODELS[model_name]

		name = CLASS_PREFIX + objective_class_name(model_name)

		model_classes << name

		classes_to_import = []

		# merge property info in one dictionary 
		# and process model data
		properties = model_info.map do |property|
			property_name = property[0]
			property_info = property[1]		


			if TYPE_HASH[property_info["type"]]
				property_info["type"] = TYPE_HASH[property_info["type"]] 
			else
				property_info["type"] = CLASS_PREFIX + property_info["type"]
				classes_to_import << property_info["type"]
			end

			node = property_info

			while node and node["of"] != nil
				of_type = node["of"]["of"] || node["of"]["type"]

				if of_type.is_a? Hash
					node["of"]["type"] = TYPE_HASH[node["of"]["type"]]
					node = node["of"]	
				else
					if of_type != nil and TYPE_HASH[of_type] == nil
						node["of"]["of"] = CLASS_PREFIX + objective_class_name(node["of"]["of"])
				 		classes_to_import << CLASS_PREFIX + objective_class_name(of_type)
				 	end

					if node["of"]["type"] != nil and TYPE_HASH[node["of"]["type"]] != nil
						node["of"]["type"] = TYPE_HASH[node["of"]["type"]]
					end

				 	node = nil
			 	end
			end

			property_objc_name = objective_name(property_name)
			if property_objc_name == "long"
				property_objc_name = "lng"
			end

			property_info.merge({ 
				"name" => property_objc_name,
				"json_name" => property_name
			})

		end

		classes_to_import.uniq!
		classes_to_import.reject! { |classname|
			classname.match(/ExtraData/) != nil
		}

		model_info = {
			namespace_name: model_name,
			classes_to_import: classes_to_import,
			name: name,
			properties: properties
		}

		generate_model model_info
	end

	# generate class cache
end

def generate_services 
	SERVICES.keys.each do |key|
		service = SERVICES[key]

		service_name = CLASS_PREFIX + objective_class_name(key + "_service")

		requests = []

		service.keys.each do |method_name|
			method_info = service[method_name]

			# generate class names for service
			method = objective_name method_name
			request_class = CLASS_PREFIX + "#{objective_class_name key}#{objective_class_name(method_name)}Request"
			request_input = CLASS_PREFIX + objective_class_name(method_info["input_model"])			
			request_output = CLASS_PREFIX + objective_class_name(method_info["output_model"])
			request_documentation = method_info["documentation"]
			
			# wrap data
			request_info = {
				service_path: key,
				service_name: service_name,
				method_path: method_name,
				method: method,
				request_class: request_class,
				request_input: request_input,
				request_output: request_output,
				request_documentation: request_documentation
			}

			generate_request request_info

			# save request info
			requests << request_info
		end

		# wrap service info
		service_info = {
			service_name: service_name,
			requests: requests
		}

		generate_service service_info		
	end
end

# copy the base classes needed for models, request and other magic
def copy_base_files
	base_files = Dir["templates/Base/**/*"].reject { |fn| 
		File.directory?(fn) 
	}

	print "copying base base files ."

	base_files.each do |base_file|
		destination = base_file.gsub("templates", "output")

		create_folders_for_path destination

		FileUtils.cp(base_file, destination)
		print "."
	end
	print "\n"
end

# removes all files from output/
def clear_output_folder
	print "clearing output folder ."

	FileUtils.rm_rf("output/")
	
	print "..\n"
end

def generate_api_header
	@api_header_template ||= template_named "api_header.h"

	header_path = CLASS_PREFIX + "Point2APIClient.h"

	# generating context

	services = SERVICES.keys.map { |key|  
		service_name = CLASS_PREFIX + objective_class_name(key + "_service")
	}

	code = render @api_header_template, binding
	save_to_file code, header_path
end

def generate_config
	@api_config_interface_template ||= template_named "api_config.h"
	@api_config_implementation_template ||= template_named "api_config.m"

	config_name = CLASS_PREFIX + "APIConfig"

	#creating temaplate context
	prefix = CLASS_PREFIX
	api_key = API_KEY
	server_base_url = SERVER_BASE_URL

	directory_path = "Config"
	interface_path = "#{directory_path}/#{config_name}.h"
	implementation_path = "#{directory_path}/#{config_name}.m"

	interface_code = render @api_config_interface_template, binding
	save_to_file interface_code, interface_path

	implementation_code = render @api_config_implementation_template, binding
	save_to_file implementation_code, implementation_path
end

def generate_api_client
	clear_output_folder

	generate_models
	generate_services

	generate_config
	
	generate_api_header

	copy_base_files

	puts "generated #{@number_of_files} files"
end

generate_api_client






