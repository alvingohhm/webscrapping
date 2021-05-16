require './lib/browser_controller'
require 'nokogiri'
require 'watir-scroll'
require 'json'

class ListingPage
  attr_accessor :base_directory, :page_directory, :log_trace, :page
  attr_reader :transaction_api_check

  def initialize (base_directory, logfile)
    @base_directory = base_directory
    @log_trace = logfile
  end

  def directory_exists?(directory)
    if File.directory?(directory)
      return true
    else
      return false
    end
  end

  def start_process (page_url, link_no)
    @page_directory = @base_directory + page_url.split('/').last + "/"
    # random_boolean = [true, false].sample
    @page = BrowserController.new(true, true)
    @page.url = page_url
    @page.open_browser(2)
    @page.browser.window.resize_to(1200, 1000)
    # @page.browser.driver.manage.window.maximize

    @log_trace.write_section = "Start Browser & Individual Page Process @ #{page_url.split('/').last} listing no: #{link_no}"
    @log_trace.write_content = "URL--> #{page_url}"
    # @page = @controller.browser
    @page.browser_wait_until_present('//div[@id="listingPageContent"]', 10)

    @page.browser.scroll.to :bottom
    @page.browser_wait (1)
    @page.browser.scroll.to :top
    @page.browser_wait (3)
    # @page.browser_wait_until_present('//div[@id="content"]//div[@id="location"]', 10)
    place_section = @page.browser.div(xpath: '//div[@id="content"]//div[@id="location"]')

    if place_section.exist?
      place_section.wd.location_once_scrolled_into_view
    end

    transaction_history_section = @page.browser.element(xpath: '//div[@id="transactions"]//div[contains(@class, "TransactionsStats")]//following-sibling::div[1]//p[contains(@class, "noData")]')

    if not transaction_history_section.exist?
      @transaction_api_check = true
      doc = Nokogiri::HTML.parse(@page.browser.html)
      inline_script = doc.xpath('/html[1]/body[1]/script[not(@type) and @data-reactid][1]')
      inline_text = inline_script.text
      inline_text.slice! "window.__data="
      inline_text = inline_text.gsub(/\;/,"")
      json_data = JSON.parse(inline_text)
      api_id = json_data["listing"]["data"]["info"]["cluster_id"]
      @page.browser_wait_until_present('//div[@id="transactions"]//ul[contains(@class, "PaginationList")]', 10)
      transaction_pagination_section = @page.browser.element(xpath: '//div[@id="transactions"]//ul[contains(@class, "PaginationList")]')
      if transaction_pagination_section.exist?
        transaction_last_page_no = transaction_pagination_section.as(xpath: '//a[@aria-label]').last.text
      end
      transaction_page_size = (transaction_last_page_no.to_i * 20).to_s
      #below url is sensored. try ur url here
      @api_url = "https://www.xx.xx/api/v1/web/clusters/#{api_id}/transactions/table/history?transaction_type=sale&page_num=1&page_size=#{transaction_page_size}"
    else
      @log_trace.write_content = "No Api Data"
      @transaction_api_check = false
    end

    @nextArrow = @page.browser.div(xpath: '//div[@id="location"]//div[contains(@class, "nextArrow")]')
    @prevArrow = @page.browser.div(xpath: '//div[@id="location"]//div[contains(@class, "prevArrow")]')

    if @nextArrow.exist?
      @nextArrow.click
      @page.browser_wait(2)
      @prevArrow.click
    end
    @page.browser_wait(2)
  end

  def save_listing_page(file_name)
    file_full_path = @page_directory + file_name
    @log_trace.write_content = "# Saving Listing Page #{file_full_path}"
    # if not directory_exists?(@page_directory)
    #   @log_trace.write_content = "error: Method-save_index_page, Desc-saving #{file_full_path} unsucessfully"
    #   return false
    # end
    doc = Nokogiri::HTML.parse(@page.browser.html)
    File.open(file_full_path , 'w') do |file|
      file.puts doc
    end
    @log_trace.write_content = "# ----- End of Saving Listing Page -----"
    # @page.browser_wait(2)
    return true
  end

  def save_api_page
    file_full_path = @page_directory + "transaction_history.json"
    # random_boolean = [true, false].sample
    @page2 = BrowserController.new(true, true)
    @page2.url = @api_url
    @page2.open_browser(2)
    @log_trace.write_content = "$ Downloading Api - #{@api_url}"
    # @page2 = controller2.browser
    @page2.browser_wait(5)

    doc = Nokogiri::HTML.parse(@page2.browser.html)
    myjson = JSON.parse(doc)
    File.open(file_full_path, 'w') do |file|
      file.write (myjson.to_json)
    end
    @page2.browser_wait(2)
    @page2.browser.close
    @page2 = nil
    @log_trace.write_content = "$ ----- Downloading Api Complete -----"
  end

  def nearby_places_available?
    nearbyPlaces = @page.browser.divs(xpath: '//div[@id="location"]//div[@class="slick-track"]//div[contains(@class, "component_wrapper__pcTE3")]')
    if nearbyPlaces.size == 1
      nearbyPlace = nearbyPlaces[0]
      nearbyPlace_category = nearbyPlace.div(class: /label/).text.gsub(/(?<=\w)\w+/, &:downcase)
      if nearbyPlace_category == "Commute"
        commuteTabs_section = @page.browser.div(xpath: '//div[@id="location"]//div[contains(@class, "CommuteTabs")]')
        if commuteTabs_section.exist?
          return true
        else
          return false
        end
      end
    else
      return true
    end
  end

  def processing_nearby
    @log_trace.write_content = "<Processing Nearby Places>"
    focus_view = @page.browser.div(xpath: '//div[@id="location"]//div[contains(@class, "lists_wrapper_full")]')
    if focus_view.exist?
      focus_view.wd.location_once_scrolled_into_view
    end
    if nearby_places_available?
      nearbyPlaces = @page.browser.divs(xpath: '//div[@id="location"]//div[@class="slick-track"]//div[contains(@class, "component_wrapper__pcTE3")]')
      nearbyPlaces.each do |nearbyPlace|
        if not nearbyPlace.class_name.include? "slick-active"
          @nextArrow.click
          @page.browser_wait(2)
        end
        nearbyPlace_button = nearbyPlace.div(class: /button/)
        nearbyPlace_button.click
        @page.browser_wait(rand(2..3))
        nearbyPlace_category = nearbyPlace.div(class: /label/).text.gsub(/(?<=\w)\w+/, &:downcase)

        if nearbyPlace_category == "Commute"
          commuteTabs_section = @page.browser.div(xpath: '//div[@id="location"]//div[contains(@class, "CommuteTabs")]')
          if commuteTabs_section.exist?
            commuteTabs = @page.browser.divs(xpath: '//div[@id="location"]//div[contains(@class, "CommuteTabs")]//div[contains(@class, "CommuteTab")]')
            commuteTabs.each do |commuteTab|
              commuteTab.click
              @page.browser_wait(2)
              nearbyPlace_subCategory = commuteTab.text
              @log_trace.write_content = "----- Saving Nearby Places - #{nearbyPlace_category}-#{nearbyPlace_subCategory} -----"
              save_listing_page("listing-#{nearbyPlace_category}-#{nearbyPlace_subCategory}.html")
            end
            next
          end
        end
        @log_trace.write_content = " -----Saving Nearby Places - #{nearbyPlace_category} -----"
        save_listing_page("listing-#{nearbyPlace_category}.html")
      end
    else
      @log_trace.write_content = "No Nearby Places Data"
    end
    @log_trace.write_content = "<End of Processing Nearby Places>"
  end

  def close_browser
    @page.browser_wait(2)
    @page.browser.close
    @page = nil
  end
end