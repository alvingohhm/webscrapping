require './lib/browser_controller'
require './lib/log_file'
require 'nokogiri'
require 'watir-scroll'

class ListingTable
  attr_accessor :property_type, :page_num_to_start, :listing_size_per_page
  attr_accessor :base_directory, :primary_url, :listing_page, :pagination_next, :pagination_prev, :log_trace, :duration
  attr_reader :base_url, :listing_links

  def initialize (select_property_type=0, select_page_num_start=1, select_listing_size_per_page=20)
    assigned_property_type = ["hdb", "condo", "landed"]
    # enter root url of website to scrap here eg. https://www.google.com/
    @base_url = "Enter root url here"
    @property_type = assigned_property_type[select_property_type]
    @page_num_to_start = select_page_num_start
    @listing_size_per_page = select_listing_size_per_page
    @base_directory = File.join(File.absolute_path('..', File.dirname(__FILE__)), property_type,"/")
    @primary_url = base_url + "singapore/sale?listing_type=sale&main_category=#{property_type}&page_num=#{page_num_to_start}&page_size=#{listing_size_per_page}&sort_field=updated_at&sort_order=desc"
    @log_trace = LogFile.new(File.join(File.absolute_path('..', File.dirname(__FILE__)), "log","/log-#{property_type}-#{page_num_to_start}_#{listing_size_per_page}.txt"))
  end

  def directory_exists?(directory)
    if File.directory?(directory)
      return true
    else
      return false
    end
  end

  def file_exists?(filepath)
    if File.exists?(filepath)
      return true
    else
      return false
    end
  end

  def start_process
    @listing_page = BrowserController.new(true, true)
    @listing_page.url = self.primary_url
    @listing_page.open_browser(2)
    # @listing_page.browser.driver.manage.window.maximize

    @log_trace.write_header = "Start Browser & Listing Index Process"

    # controller.browser_wait (5)
    @listing_page.browser_wait_until_present('//div[@id="extraHtml"]//div[contains(@class, "grid-list")]/div[@data-reactid]', 10)
    @pagination_next = @listing_page.browser.element(xpath: '//div[@id="extraHtml"]//ul[contains(@class, "SearchPagination-links")]//a[@rel="next"]')
    if @pagination_next.exist?
      @pagination_next.click
    else
      @log_trace.write_content = "error: Method-Start Process, Desc-Pagination Next Button cannot be found"
    end
    @listing_page.browser_wait (5)
    @pagination_prev = @listing_page.browser.element(xpath: '//div[@id="extraHtml"]//ul[contains(@class, "SearchPagination-links")]//a[@rel="prev"]')
    if @pagination_prev.exist?
      @pagination_prev.click
    else
      @log_trace.write_content = "error: Method-Start Process, Desc-Pagination Prev Button cannot be found"
    end
    # @listing_page.browser_wait_until_present('//div[@id="extraHtml"]//div[contains(@class, "grid-list")]/div[@data-reactid]', 10)
    @listing_page.browser.scroll.to :bottom
    @listing_page.browser.scroll.to :top
    @listing_page.browser_wait (15)
  end

  def pagination_button_click (page_num)
    pagination_section = @listing_page.browser.element(xpath: '//div[@id="extraHtml"]//ul[contains(@class, "SearchPagination-links")]')
    if pagination_section.exist?
      pagination_section.wd.location_once_scrolled_into_view
      pagination_button = pagination_section.a(aria_label: "Page #{page_num.to_s}")
      if pagination_button.exist?
        pagination_button.click
        @listing_page.browser_wait (15)
        return true
      else
        if @pagination_next.exist?
          @pagination_next.click
        else
          @log_trace.write_content = "**error: Method-pagination_button_click, Desc-pagination_button index#{page_num.to_s} does not exist"
          return false
        end
      end
    else
      @log_trace.write_content = "**error: Method-pagination_button_click, Desc-pagination section does not exist"
      return false
    end
  end

  def get_last_page_num
    @listing_page.browser.elements(xpath: '//div[@id="extraHtml"]//ul[contains(@class, "SearchPagination-links")]//a[@aria-label]').last.text
  end

  def save_index_page(file_path, file_name)
    file_full_path = file_path + file_name
    @log_trace.write_content = "# Saving Index Page #{file_full_path}"
    if not directory_exists?(file_path)
      @log_trace.write_content = "**error: Method-save_index_page, Desc-saving #{file_full_path} unsucessfully"
      return false
    end
    doc = Nokogiri::HTML.parse(@listing_page.browser.html)
    # doc.xpath('//@style').remove
    File.open( file_full_path , 'w') do |file|
      # file.puts doc.at('body')
      file.puts doc
    end
    # File.write(file_full_path, doc)
    @log_trace.write_content = "# ----- End of Saving Index Page -----"
    # @listing_page.browser_wait (1)
    return true
  end

  def get_all_listing_links
    listing_container = @listing_page.browser.elements(xpath: '//div[@id="extraHtml"]//div[contains(@class, "grid-list")]/div[@data-reactid]//a[@data-click-id="listing-item"]')
    @listing_links = []
    @listing_links = listing_container.map {|element| element.href}.compact
  end

  def create_listing_folders
    @log_trace.write_content = "% Create Listing Folders"
    duplicate_links = []
    @listing_links.each do |link|
      directory_path = @base_directory + link.split('/').last
      if directory_exists?(directory_path)
        duplicate_links << link
        @log_trace.write_content = "**Note:Folder #{directory_path} already exist."
      else
        Dir.mkdir(directory_path)
      end
    end
    @listing_links -= duplicate_links unless duplicate_links.empty?
    # @listing_page.browser_wait (3)
    @log_trace.write_content = "% ----- End of Create Listing Folders -----"
  end

  def start_timer
    @start_time = Time.now
  end

  def end_timer
    time_difference = Time.now - @start_time
    @duration = nil
    @duration = Time.at(time_difference).utc.strftime("%H:%M:%S")
  end


end
