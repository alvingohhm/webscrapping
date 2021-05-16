require 'pry-byebug'
require 'nokogiri'
require 'csv'
require 'open-uri'

property_type='hdb'
listing_ids = []
listing_details = []
listing_details << ['Id', 'Listing_Title', 'Listing_Address', 'Listed_at', 'No_of_Bed', 'No_of_Bathrm', 'Sqft', 'Sqm', 'Psf', 'Price', 'Key_Details', 'Availability','Facing', 'District', 'Amenities', 'Description', 'Total_Units', 'Years_of_Completion']
agents_details = []
agents_details << ['Id', 'Agent_Name', 'Agent_Company','Estate_Agent_License_No', 'Registration_No', 'Response_Rate']

saved_html_path = File.join(File.absolute_path('.', File.dirname(__FILE__)),"#{property_type}","/in_progress/")
listing_details_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)),"csv","#{property_type}-listing_details.csv")
agents_details_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)),"csv","#{property_type}-agents_details.csv")

Dir[saved_html_path + '*'].each do |filename|
  listing_ids << filename
end
counter = 0
total_count = listing_ids.size

listing_ids.each do |listing_id|
  counter += 1
  id = listing_id.split("/").last.gsub(".html", "")
  p "Processing row: #{counter}/#{total_count} and id:#{listing_id}"
  page = Nokogiri::HTML(open(listing_id))

  listing_title =  page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/div[1]/a[1]/h1[1]').text
  property_type == 'hdb' ? listing_address = listing_title : listing_address = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/p[1]').text.split(',').first

  listed_at = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/p[2]/span[1]').text
  no_of_bed = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/div[2]/div[1]/div[2]/p[1]').text.split(" ").first
  no_of_bathrm = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/div[2]/div[2]/div[2]/p[1]').text.split(" ").first
  sqft = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/div[2]/div[3]/div[2]/p[1]').text.split(" ").first
  sqm = (sqft.to_i * 0.092903).round(2)
  psf = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[2]/div[2]/div[4]/div[2]/p[1]').text.gsub(/[(S psf)]/, "").strip
  price = page.xpath('id("appContent")/div[1]/div[3]/div[1]/div[3]/h3[2]').text.gsub(/[(S)]/, "").strip

  nodes = page.xpath('id("keyDetails")/div[1]')
  availability = 'nil'
  facing = 'nil'
  district = 'nil'
  key_details_container = []
  nodes.children.each do |node|
    matching_title = node.children[0].text.downcase
    case matching_title
      when "availability"
        availability = node.children[1].text
      when "facing"
        facing = node.children[1].text
      when "district"
        district = node.children[1].text
      else
        key_details_container << node.children[0].text + ": " + node.children[1].text
    end
  end

  if key_details_container.empty? then
    key_details = 'nil'
  else
    key_details = key_details_container.join("|")
  end

  amenities_container =[]
  nodes = page.xpath('id("listingPageContent")/div[1]/div[2]/div[1]')
  nodes.children.each do |node|
    amenities_container << node.text
  end
  if amenities_container.empty? then
    amenities = 'nil'
  else
    amenities = amenities_container.join("|")
  end

  description = page.xpath('id("description")/pre[1]').text
  total_units = page.xpath('id("development")/div[1]/div[2]/p[2]').text.split(" ").last
  years_of_completion = page.xpath('id("development")/div[1]/div[2]/p[3]').text.split(" ").last

  agent_name = page.xpath('id("listingPageContent")/div[2]/div[1]/div[1]/div[1]/div[2]/a[1]/h3[1]').text
  agent_company = page.xpath('id("listingPageContent")/div[2]/div[1]/div[1]/div[1]/div[2]/p[1]').text
  estate_agent_license_no = page.xpath('id("listingPageContent")/div[2]/div[1]/div[1]/div[1]/div[2]/p[2]').text.split(" ")[1]
  registration_no = page.xpath('id("listingPageContent")/div[2]/div[1]/div[1]/div[1]/div[2]/p[2]').text.split(" ").last
  response_rate = page.xpath('id("listingPageContent")/div[2]/div[1]/div[1]/div[1]/div[2]/div[1]/p[1]').text.split(" ").last

  listing_details << [id, listing_title, listing_address, listed_at, no_of_bed, no_of_bathrm, sqft, sqm, psf, price, key_details, availability, facing, district, amenities, description, total_units, years_of_completion]
  agents_details << [id, agent_name, agent_company, estate_agent_license_no, registration_no, response_rate]
end

CSV.open(listing_details_csv_path, "a") do |csv_file|
  listing_details.each do |row|
    csv_file << row
  end
end

CSV.open(agents_details_csv_path, "a") do |csv_file|
  agents_details.each do |row|
    csv_file << row
  end
end

# binding.pry
puts "Finished!"