require './lib/log_file'
require 'nokogiri'
require 'csv'
require 'fileutils'

class ListingSummary
  attr_reader :index_page_lists, :listing_folders, :base_directory, :property_type
  attr_accessor :log_trace

  def initialize (select_property_type=0)
    assigned_property_type = ["hdb", "condo", "landed"]
    @property_type = assigned_property_type[select_property_type]
    @base_directory = File.join(File.absolute_path('..', File.dirname(__FILE__)), @property_type,"/")
    @summary_csv_path = File.join(File.absolute_path('..', File.dirname(__FILE__)),"csv",@property_type,"#{@property_type}-listing_summary.csv")
    data_fields = Struct.new :id, :no_of_photos, :prpty_title, :location_short, :property_type, :property_category, :ownership,
    :ageny_only_on_99, :premium_agent, :verified, :additional_info, :agent_highlights, :page_no, :row_no
    @summary_data = data_fields.new
    @log_trace = LogFile.new(File.join(File.absolute_path('..', File.dirname(__FILE__)), "log","/log-#{@property_type}-process-extraction.txt"))
  end

  def create_summary_csv
    File.open(@summary_csv_path, "w") {}
    header_row = []
    @summary_data.to_h.map { |k,v| header_row << k.to_s}
    write_csv(@summary_csv_path, header_row)
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

  def get_all_index_page
    @index_page_lists = Dir[@base_directory + "*.html"]
  end

  def parse_index_page (listing_page, page_no)
    @index_page_no = page_no
    @page = Nokogiri::HTML(open(listing_page))
  end


  def check_is_banner? (container)
    element = container.xpath('./div[contains(@class, "ListingItem")]')
    if element.empty?
      return true
    else
      return false
    end
  end

  def directory_exists?(directory)
    if File.directory?(directory)
      return true
    else
      return false
    end
  end

  def get_all_listing
    data_rows = []
    @listing_folders = []
    listing_no = 0
    listing_grid = @page.xpath('//div[@id="extraHtml"]//div[contains(@class, "grid-list")]/div[@data-reactid]/div')

    listing_grid.each do |listing|
      if check_is_banner?(listing)
        next
      end
      listing_no += 1
      @log_trace.write_content = "#Scanning listing no #{listing_no}"
      # id section
      element = listing.xpath('.//a[@data-click-id="listing-item"]/@href')
      if not element.empty?
        @summary_data.id = element.text.split('/').last.strip
        folder = @base_directory + @summary_data.id + "/*"
        if Dir[folder].empty?
          next
        else
          folder = @base_directory + "Done" + "/" + @summary_data.id
          if directory_exists?(folder)
            next
          else
            @listing_folders << @base_directory + @summary_data.id + "/"
          end
        end
      else
        next
      end
      # no_of_photos section
      element = listing.xpath('.//span[@class="js-listingCard-photos"]')
      if element.empty?
        @summary_data.no_of_photos = 0
      else
        @summary_data.no_of_photos = element.text.split('/').last.strip
      end
      # prpty_title section
      element = listing.xpath('.//h4[contains(@class, "ListingItem-title")]/text()')
      if element.empty?
        @summary_data.prpty_title = "nil"
      else
        @summary_data.prpty_title = element.text.strip
      end
      # location_short section
      element = listing.xpath('.//div[contains(@class, "location")]/text()') # summary.location_short
      if element.empty?
        @summary_data.location_short = "nil"
      elsif element.text.include? "District"
        @summary_data.location_short = @summary_data.prpty_title
      else
        @summary_data.location_short = element.text.split(/\u00B7/).first.strip
      end
      # property_type section
      @summary_data.property_type = @property_type
      # property_category section
      element = listing.xpath('.//div[contains(@class, "location")]/following-sibling::div[1]/text()')
      if element.empty?
        @summary_data.property_category = @property_type
      elsif element.text.include? "-Room"
        @summary_data.property_category = element.text.split('(').first.strip
      else
        @summary_data.property_category = element.text.strip
      end
      # ownership section
      element = listing.xpath('.//div[contains(@class, "location")]/following-sibling::div[2]/text()')
      if element.empty?
        if @property_type == 'hdb'
          @summary_data.ownership = '99 years'
        else
          @summary_data.ownership = 'nil'
        end
      else
        @summary_data.ownership = element.text.split(/\u00B7/).last.strip
      end
      # ageny_only_on_99 section
      element = listing.xpath('.//div[contains(@class, "container__ujT8g") and  contains(@class, "hasBorder__fH5jQ")]')
      @summary_data.ageny_only_on_99 = 'n'
      if not element.empty?
        @summary_data.ageny_only_on_99 = 'y'
      end
      # premium_agent section
      element = listing.xpath('.//img[@class = "premiumAgentCrown"]')
      @summary_data.premium_agent = 'n'
      if not element.empty?
        @summary_data.premium_agent = 'y'
      end
      # verified section
      element = listing.xpath('.//span[@class = "verifiedText"]')
      @summary_data.verified = 'n'
      if not element.empty?
        @summary_data.verified = 'y'
      end if
      # additional_info section
      element = listing.xpath('.//div[contains(@class, "location")]/following-sibling::div[2]/text()')
      if element.empty?
        @summary_data.additional_info = "nil"
      else
        @summary_data.additional_info = element.text.split(/\u00B7/).first.strip
      end
      # agent_highlights section
      element = listing.xpath('.//div[contains(@class, "highlight__K4Fs8")]/text()')
      if element.empty?
        @summary_data.agent_highlights = "nil"
      else
        @summary_data.agent_highlights = element.text.split.join(' ')
      end
      # page_no section
      @summary_data.page_no = @index_page_no
      # row_no section
      @summary_data.row_no = listing_no

      data_rows << @summary_data.values
      @log_trace.write_content = "#End of listing no #{listing_no}"
    end
    if not data_rows.empty?
      write_csv(@summary_csv_path, data_rows)
      @log_trace.write_content = "Successful Writing data to csv file for page #{@index_page_no}"
    end
  end

  def archive_folder(current_folder, archive_folder_name)
    current_folder_path = current_folder[0..-2]
    folder_array = current_folder_path.split("/")
    content_folder_name = folder_array.pop
    current_folder_parent_path = folder_array.join("/")
    archive_folder_path = current_folder_parent_path + "/" + archive_folder_name + "/" #+ content_folder_name
      # FileUtils.copy_entry @source, @destination
    # FileUtils.cp_r(current_folder_path, archive_folder_path)
    # FileUtils.rm_r(current_folder_path)
      # FileUtils.mv(current_folder_path, archive_folder_path)
      # sleep 10

  end

  def archive_index_page(index_page, archive_folder_name)
    current_page_path = index_page
    file_array = current_page_path.split("/")
    file_name = file_array.pop
    file_parent_path = file_array.join("/")
    archive_file_path = file_parent_path + "/" + archive_folder_name + "/" + file_name
    FileUtils.mv current_page_path, archive_file_path
    # sleep 1
  end

end