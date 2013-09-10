require 'json'
require 'nokogiri'
require 'open-uri'

documentation_link = "https://developer.apple.com/library/ios/documentation/cocoa/Reference/ObjCRuntimeRef/Reference/reference.html#//apple_ref/c/func/class_getName"

documentation = nil

begin
documentation = open('documentation.html')
rescue 
end
if documentation == nil
	documentation = open(documentation_link)
end

doc = Nokogiri::HTML(documentation)



def nodes_with_xpath xpath, doc

	nodes = doc.xpath(xpath)

	# nodes.each do |node|
	# 	puts node.text
	# end

	# # puts "=" * 80
	# # puts "#{nodes.count} nodes found for xpath #{xpath}"

	return nodes
end

function_name_xpath = '//*[@id="contents"]/section[3]/h3'
abstract_xpath = '//*[@id="contents"]/section[3]/p'
declaration_xpath = '//*[@id="contents"]/section[3]/pre'
return_value_xpath = '//*[@id="contents"]/section[3]/div[@class="return_value"]'
api_discussion_xpath = '//*[@id="contents"]/section[3]/div[@class="api discussion"]'
api_availability_xpath = '//*[@id="contents"]/section[3]/div[@class="api availability"]'
api_declaration_xpath = '//*[@id="contents"]/section[3]/div[@class="api declaredIn"]'
api_parameters_xpath = '//*[@id="contents"]/section[3]/div[@class="api parameters"]'

function_name_nodes = nodes_with_xpath function_name_xpath, doc			
abstract_nodes = nodes_with_xpath abstract_xpath, doc			
declaration_nodes = nodes_with_xpath declaration_xpath, doc			
return_value_nodes = nodes_with_xpath return_value_xpath, doc			
api_discussion_nodes = nodes_with_xpath api_discussion_xpath, doc			
api_availability_nodes = nodes_with_xpath api_availability_xpath, doc			
api_declaration_nodes = nodes_with_xpath api_declaration_xpath, doc			
api_parameters_nodes = nodes_with_xpath api_parameters_xpath, doc			

functions_info = []

function_name_nodes.each do |function_name_node|
	function_info = {
		name: function_name_node.text
	}

	# puts "-" * 80
	# puts function_name_node.text
	# puts "-" * 80

	node = function_name_node

	while node.next_element and node.next_element.name != 'h3'
		node = node.next_element
		
		if node == abstract_nodes.first
			# puts "* #{node.text}"
			poped_node = abstract_nodes.shift
			function_info[:abstract] = poped_node.text
			# function_info[:abstract_xml] = poped_node
		end

		if node == declaration_nodes.first
			# puts "* #{node.text}"
			poped_node = declaration_nodes.shift
			function_info[:declaration] = poped_node.text.gsub("\n", "")
			function_info[:declaration_xml] = poped_node
		end

		if node == return_value_nodes.first
			# puts "* #{node.text}"
			poped_node = return_value_nodes.shift
			function_info[:return_value] = poped_node.text
			function_info[:return_value_xml] = poped_node
		end

		if node == api_discussion_nodes.first
			# puts "* #{node.text}"
			poped_node = api_discussion_nodes.shift
			function_info[:api_discussion] = poped_node.text
			function_info[:api_discussion_xml] = poped_node
		end

		if node == api_availability_nodes.first
			# puts "* #{node.text}"
			poped_node = api_availability_nodes.shift
			function_info[:api_availability] = poped_node.text
			function_info[:api_availability_xml] = poped_node
		end

		if node == api_declaration_nodes.first
			# puts "* #{node.text}"
			poped_node = api_declaration_nodes.shift
			function_info[:api_declaration] = poped_node.text
			function_info[:api_declaration_xml] = poped_node
		end

		if node == api_parameters_nodes.first
			# puts "* #{node.text}"
			poped_node = api_parameters_nodes.shift
			function_info[:api_parameters] = poped_node.text
			function_info[:api_parameters_xml] = poped_node


			param_names = node.xpath("#{node.path}/dl/dt")
			param_descriptions = node.xpath("#{node.path}/dl/dd")

			# puts param_names.count == param_descriptions.count ? "YEY" : "FUCK MY LIFE"
			declaration = function_info[:declaration]

			matches = declaration.match(/\((?<declaration>.*)\)/)

			param_info = matches['declaration'].split(",").map { |s|
				if s['...'] != nil 
					{
						type: 'va_list',
						name: 'va_list'
					}
				else 
					match = s.match(/(?<name>\w+)$/)
					
					name = match['name']

					type = s + "$"					
					type[name + "$"] = ""

					{
						type: type,
						name: name
					}
				end
			}			
			
			parameters = []

			while param_names.count > 0 and param_descriptions.count > 0
				name = param_names.shift
				description = param_descriptions.shift
				type = "TYPE"

				param_info.each do |pi|
					if pi[:name][name.text] != nil
						type = pi[:type].gsub(/^\s+/, "").gsub(/\s+$/, "")
					end
				end

				parameters << {
					name: name.text,
					description: description.text,
					type: type
				}
			end

			function_info[:parameters] = parameters
		end

	end

	functions_info << function_info
end

puts JSON.pretty_generate(functions_info)


























