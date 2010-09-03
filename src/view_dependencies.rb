require 'rexml/document'
require 'rexml/element'

WORKBOOK_NODE = "workbook"
DATASOURCES_NODE = "datasources"
DATASOURCE_NODE = "datasource"
CONNECTION_NODE = "connection"
RELATION_NODE = "relation"

DBNAME_ATTRIBUTE = "dbname"
TABLE_ATTRIBUTE = "table"

files = Dir.glob(ARGV[0])

files.each do |f|
  workbook_dependencies = {}

  begin
    workbook = REXML::Document.new File.new(f)
  rescue REXML::ParseException => e
    puts "!!! #{e}"
    next
  end

  unless workbook and workbook.root
    puts "!!! Malformatted XML"
    next
  end

  workbook.root.each_element_with_attribute("#{WORKBOOK_NODE}/#{DATASOURCES_NODE}/#{DATASOURCE_NODE}").each do |el|
    el.get_elements(DATASOURCE_NODE).each do |datasource|
      datasource.get_elements(CONNECTION_NODE).each do |connection|
        dbname = connection.attributes[DBNAME_ATTRIBUTE]
        workbook_dependencies[dbname] ||= []

        connection.get_elements(RELATION_NODE).each do |relation|
          workbook_dependencies[dbname] << relation.attributes[TABLE_ATTRIBUTE]
        end
      end
    end
  end

  next if workbook_dependencies.empty?

  puts "Workbook: #{f}"
  workbook_dependencies.each_key do |dbname|
    workbook_dependencies[dbname].compact!

    next if workbook_dependencies[dbname].empty?
    workbook_dependencies[dbname].uniq!

    puts "          Database: #{dbname}"
    puts "                    " + workbook_dependencies[dbname].sort.join("\n                    ")
  end
  puts
end