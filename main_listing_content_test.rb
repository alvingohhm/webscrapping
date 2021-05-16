require 'nokogiri'
require 'json'
require 'csv'

@details_data_rows = []
@agent_data_rows = []
@community_data_rows = []
folders_dir = []
@property_type = 'landed'

details_fields = Struct.new :id, :listing_title, :listing_address, :listed_at, :no_of_bed, :no_of_bathrm, :sqft,
:sqm, :psf, :price, :key_details, :availability, :facing, :district, :amenities, :description,
:total_units, :years_of_completion

agent_fields = Struct.new :id, :agent_name, :agent_company, :estate_agent_license_no, :registration_no, :response_rate
community_fields = Struct.new :id, :place_category, :commute_by, :nearby_place_name, :commute_price, :distant, :duration_taken, :bus_qty, :bus_no
transaction_fields = Struct.new :id, :date, :block, :unit, :area_sqft, :area_sqm, :price, :price_psf

@details_data = details_fields.new
@agent_data = agent_fields.new
@community_data = community_fields.new
@transaction_data = transaction_fields.new

base_directory = File.join(File.absolute_path('.', File.dirname(__FILE__)), "landed")
@target_directory = File.join(base_directory, "burghley-drive-landed-Rao2RVGS6wyLZWKjepfF3K")
directory = @target_directory + "/*"
html_lists = Dir[directory]
directory = @target_directory + "/*.json"
# jsonfile = Dir[directory]

def process_details_page (html_page)
  page = Nokogiri::HTML(open(html_page))
  @details_data.id = @target_directory.split('/').last
  @agent_data.id = @details_data.id
  summary_section =  page.xpath('//div[@id="appContent"]//div[contains(@class, "summaryContainer")]')
  # listing_title section
  element = summary_section.xpath('.//div[contains(@class, "titleContainer")]//h1[contains(@class, "heading")]/text()')
  @details_data.listing_title = "nil"
  if not element.empty?
    @details_data.listing_title = element.text.strip
  end
  # listing_address section
  if @property_type == "hdb"
    @details_data.listing_address = @details_data.listing_title
  else
    element = summary_section.xpath('.//div[contains(@class, "titleContainer")]/following-sibling::p[1]/text()')
    if element.empty?
      @details_data.listing_address = "nil"
    else
      if element.text.split(',').first.include? "District"
        @details_data.listing_address = "nil"
      else
        @details_data.listing_address = element.text.split(',').first.strip
      end
    end
  end
  # listed_at section
  element = summary_section.xpath('.//div[contains(@class, "titleContainer")]/following-sibling::p[2]/span/text()')
  @details_data.listed_at = "nil"
  if not element.empty?
    @details_data.listed_at = element.text.strip
  end
  # :no_of_bed, :no_of_bathrm, :sqft, :sqm, :psf section
  element = summary_section.xpath('.//div[contains(@class, "summaryTextContainer")]/p[contains(@class, "Text")]/text()')
  @details_data.no_of_bed = "nil"
  @details_data.no_of_bathrm = "nil"
  @details_data.sqft = 0
  @details_data.sqm = 0
  @details_data.psf = 0

  if not element.empty?
    element.each do |category|
      case category.text
        when /Bed/
          @details_data.no_of_bed = category.text.split(" ").first
        when /Bath/
          @details_data.no_of_bathrm = category.text.split(" ").first
        when /sqft/
          @details_data.sqft = category.text.split(" ").first
          @details_data.sqm = (@details_data.sqft.to_i * 0.092903).round(2)
        when /psf/
          @details_data.psf = category.text.gsub(/[(S psf)]/, "").strip
      end
    end
  end
  # :price section
  element = summary_section.xpath('.//div[contains(@class, "rightColumn")]/h3[contains(@class, "heading")]/text()')
  @details_data.price = 0
  if not element.empty?
    @details_data.price = element.text.gsub(/[(S)]/, "").strip
  end

  key_detail_items =  page.xpath('//div[@id="keyDetails"]/div[contains(@class, "keyDetailContainer")]/div[contains(@class, "keyDetailItem")]')
  # :key_details, :availability, :facing, :district section
  @details_data.key_details = []
  @details_data.availability = "nil"
  @details_data.facing = "nil"
  @details_data.district = "nil"
  if not key_detail_items.empty?
    key_detail_items.each do |key_detail_item|
      tag = key_detail_item.xpath('.//div[contains(@class, "tag")]').text.strip.downcase
      tag_detail = key_detail_item.xpath('.//p[contains(@class, "text")]').text.strip
      case tag
        when "availability"
          @details_data.availability = tag_detail
        when "facing"
          @details_data.facing = tag_detail
        when "district"
          @details_data.district = tag_detail
        else
          @details_data.key_details << tag + ": " + tag_detail
      end
    end
  end
  if @details_data.key_details.empty?
    @details_data.key_details = 'nil'
  else
    @details_data.key_details *= "|"
  end

  # :amenities section
  amenities = page.xpath('//div[@id="listingPageContent"]//div[contains(@class, "amenitiesContainer")]/div[contains(@class, "amenity")]/p[contains(@class, "amenityLabel")]')
  @details_data.amenities =[]
  if not amenities.empty?
    amenities.each do |amenity|
      @details_data.amenities << amenity.text.strip
    end
  end
  if @details_data.amenities.empty? then
    @details_data.amenities = 'nil'
  else
    @details_data.amenities *= "|"
  end
  # :description section
  element = page.xpath('//div[@id="description"]/pre[contains(@class, "text")]/text()')
  @details_data.description = "nil"
  if not element.empty?
    @details_data.description = element.text.strip.split.join(' ')
  end
  # :total_units, :years_of_completion section
  development_details = page.xpath('//div[@id="development"]/div[contains(@class, "container")]/div[contains(@class, "info")]/p[contains(@class, "text")]')
  @details_data.total_units = "nil"
  @details_data.years_of_completion  = "nil"
  if not development_details.empty?
    development_details.each do |detail|
      development_detail = detail.text.strip.split(" ").last
      case detail.text
        when /Total Units/
          if development_detail != "None"
            @details_data.total_units = development_detail
          end
        when /Year of Completion/
          @details_data.years_of_completion = development_detail
      end
    end
  end

  # :agent_name section
  agent_section = page.xpath('//div[@id="listingPageContent"]//div[contains(@class, "containerTop")]//div[contains(@class, "agentInfo")]')
  element = agent_section.xpath('.//h3[contains(@class, "sectionTitle")]/text()')
  @agent_data.agent_name = "nil"
  if not element.empty?
    @agent_data.agent_name = element.text.strip
  end
  # :agent_company section
  element = agent_section.xpath('./p[contains(@class, "text")][1]/text()')
  @agent_data.agent_company = "nil"
  if not element.empty?
    @agent_data.agent_company = element.text.strip
  end
  # :estate_agent_license_no, :registration_no section
  element = agent_section.xpath('./p[contains(@class, "text")][2]/text()')
  @agent_data.estate_agent_license_no = "nil"
  @agent_data.registration_no = "nil"
  if not element.empty?
    @agent_data.estate_agent_license_no = element.text.strip.split(" ")[1]
    @agent_data.registration_no = element.text.strip.split(" ").last
  end
  # :response_rate section
  element = agent_section.xpath('./div[contains(@class, "agentResponse")]/p[contains(@class, "agentResponseText")]/text()')
  @agent_data.response_rate = "nil"
  if not element.empty?
    @agent_data.response_rate = element.text.strip.split(" ").last
  end

  @details_data_rows << @details_data.values
  @agent_data_rows << @agent_data.values
  details_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)), "test", "details.csv")
  agent_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)), "test", "agent.csv")

  if not @details_data_rows.empty?
    write_csv(details_csv_path, @details_data_rows)
  end
  if not @agent_data_rows.empty?
    write_csv(agent_csv_path, @agent_data_rows)
  end

end

def write_csv (path, data_rows)
  CSV.open(path, "a") do |csv_file|
    if is_2d_array?(data_rows)
      data_rows.each do |row|
        csv_file << row
      end
    else
      csv_file << data_rows
    end
  end
end

def is_2d_array? (array_obj)
  array_obj.all? { |e| e.class==Array }
end

def process_commute_page (html_page)
  page = Nokogiri::HTML(open(html_page))
  @community_data.id = @target_directory.split('/').last
  # :place_category section
  @community_data.place_category = "Distant To"
  # :commute_by section
  @community_data.commute_by = html_page.split('/').last.split('-').last.gsub(".html", "")
  # :bus_qty section
  @community_data.bus_qty = "nil"
  # :bus_no section
  @community_data.bus_no = "nil"
  # :nearby_place_name, :commute_price, :distant, :duration_taken section

  commute_section = page.xpath('//div[@id="location"]//div[contains(@class, "places")]//div[contains(@class, "Commute_AddLocation__")]/following-sibling::div[1]/span/div[contains(@class, "CommutePlace__")]')

  commute_section.each do |commute_place|
    # :nearby_place_name section
    element = commute_place.xpath('.//div[contains(@class, "CommutePlace_Name")]/text()')
    @community_data.nearby_place_name = "nil"
    if not element.empty?
      @community_data.nearby_place_name = element.text.strip
    end
    # :duration_taken section
    element = commute_place.xpath('.//div[contains(@class, "CommutePlace_Duration")]/text()')
    @community_data.duration_taken = "nil"
    if not element.empty?
      @community_data.duration_taken = element.text.strip
    end
    # :commute_price section
    @community_data.commute_price = "nil"
    if @community_data.commute_by != "Driving"
      element = commute_place.xpath('.//div[contains(@class, "CommutePlace_Duration")]/following-sibling::div[1]')
      if not element.empty?
        @community_data.commute_price = element.text.strip
      end
    end
    # :distant section
    @community_data.distant = "nil"
    if @community_data.commute_by == "Driving"
      element = commute_place.xpath('.//div[contains(@class, "CommutePlace_Duration")]/following-sibling::div[1]')
      if not element.empty?
        @community_data.distant = element.text.strip
      end
    end
    @community_data_rows << @community_data.values
  end
  community_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)), "test", "community.csv")
  if not @community_data_rows.empty?
    write_csv(community_csv_path, @community_data_rows)
  end
  @community_data_rows = []
end

def process_places_page (html_page)
  page = Nokogiri::HTML(open(html_page))
  @community_data.id = @target_directory.split('/').last
  # :place_category section
  @community_data.place_category = html_page.split('/').last.split('-').last.gsub(".html", "")
  # :commute_by section
  @community_data.commute_by = "nil"
  # :commute_price section
  @community_data.commute_price = "nil"

  commute_section = page.xpath('//div[@id="location"]//div[contains(@class, "Nearby-container")]//span/div[contains(@class, "NearbyPlace__")]')
  commute_section.each do |commute_place|
    # :nearby_place_name section
    element = commute_place.xpath('.//div[contains(@class, "NearbyPlaceName")]/text()')
    @community_data.nearby_place_name = "nil"
    if not element.empty?
      @community_data.nearby_place_name = element.text.strip
    end
    # :distant section
    @community_data.distant = "nil"
    element = commute_place.xpath('.//div[contains(@class, "NearbyWalkDistance")]/text()')
    if not element.empty?
      @community_data.distant = element.text.strip
    end
    # :duration_taken section
    element = commute_place.xpath('.//div[contains(@class, "NearbyWalkDistance")]/following-sibling::div[1]/text()')
    @community_data.duration_taken = "nil"
    if not element.empty?
      @community_data.duration_taken = element.text.split("(").first.strip
    end
    # :bus_qty section
    if @community_data.place_category == "Bus Stops"
      @community_data.bus_qty = "nil"
      element = commute_place.xpath('.//div[contains(@class, "NearbyPlaceBusStations")]//span[contains(@class, "busStationOption")]/text()')
      if not element.empty?
        @community_data.bus_qty = element.size.to_s
      end
      # :bus_no section
      @community_data.bus_no = []
      if not element.empty?
        element.each do |bus_no|
          @community_data.bus_no << bus_no.text.strip
        end
      end
      if @community_data.bus_no.empty?
        @community_data.bus_no = "nil"
      else
        @community_data.bus_no *= "|"
      end
    else
      @community_data.bus_qty = "nil"
      @community_data.bus_no = "nil"
    end
    @community_data_rows << @community_data.values
  end
  community_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)), "test", "community.csv")
  if not @community_data_rows.empty?
    write_csv(community_csv_path, @community_data_rows)
  end
  @community_data_rows = []
end

def process_transaction_history (html_page)
  file = File.read(html_page)
  jdata = JSON.parse(file, object_class: OpenStruct)
  title = []
  data_rows = []
  # json title
  jdata.data.headers.each do |data_hash|
    case data_hash.title
      when "Area"
        title << "Area (sqft)" << "Area (sqm)"
      when "Price (psf)"
        title << "Transact Price" << "Price (psf)"
      else
        title << data_hash.title
    end
  end
  data_rows << title

  # json body
  jdata.data.rows.each do |row|
    data_row = []
    row.each_with_index do |data_hash, index|
      value = data_hash.title.strip
      case value
        when /sqft/
          value = value.gsub(/sqft/, "").strip
        when /\$/
          value = value.gsub(/S/, "").strip
      end
      data_row << value
      if index == 3 || index ==4
        value = data_hash.subtitle
        if value == "-"
          value = "nil"
        else
          value = data_hash.subtitle.strip.gsub(/[()]/, "")
          case value
            when /\$/
              value = value.gsub(/S/, "").gsub(/psf/, "").strip
            when /sqm/
              value = value.gsub(/sqm/, "").strip
          end
        end
        data_row << value
      end
      # (data_hash.title == "-") ? data_row << "nil" : data_row << data_hash.title.strip
    end
    data_rows << data_row
  end
  transaction_csv_path = File.join(File.absolute_path('.', File.dirname(__FILE__)), "test", "transaction_history.csv")
  if not data_rows.empty?
    write_csv(transaction_csv_path, data_rows)
  end

end
# def parse_page (html_page)
#   page = Nokogiri::HTML(open(html_page))
# end

if not html_lists.empty?
  html_lists.each do |page|
    page_name = page.split('/').last
    case page_name
      when "listing.html"
        # process_details_page(page)
      when /Commute/
        # process_commute_page(page)
      when /transaction_history/
        # process_transaction_history(page)
      else
        process_places_page(page)
    end
  end
end


# page = Nokogiri::HTML(open(index_directory))



puts "finished"