require './lib/listing_table'
require './lib/listing_page'

#----------------------------------------------------------------------------------------------------
#init argument (select_property_type, select_page_num_start, select_listing_size_per_page)
#select_property_type is an array ["hdb", "condo", "landed"]
#----------------------------------------------------------------------------------------------------

listing_tables = ListingTable.new(1,11,5)
listing_tables.start_timer
first_page_index = listing_tables.page_num_to_start
# last_page_index = listing_tables.get_last_page_num.to_i
last_page_index = 12
(first_page_index..last_page_index).each do |index_page|
  listing_tables.start_process
  listing_tables.log_trace.write_section = "Processing Index Page-#{index_page}"
  index_page_name = "index-#{index_page}.html"
  listing_tables.save_index_page(listing_tables.base_directory, index_page_name)
  listing_tables.get_all_listing_links
  listing_tables.create_listing_folders
  link_no = 0
  listing_tables.listing_links.each do |listing_link|
    listing_page = ListingPage.new(listing_tables.base_directory, listing_tables.log_trace)
    link_no += 1
    begin
      listing_page.start_process(listing_link, link_no)
    rescue Net::ReadTimeout => e
      listing_page.close_browser
      listing_page = nil
      next
      # if attempts == 0
      #   attempts += 1
      #   retry
      # else
      #   raise
      # end
    end
    listing_page.save_listing_page("listing.html")
    if listing_page.transaction_api_check
      listing_page.save_api_page
    end
    listing_page.processing_nearby
    listing_page.close_browser
  end
  listing_tables.end_timer
  listing_tables.log_trace.write_header = "End of Processing Index Page-#{index_page} - Total Time Taken #{listing_tables.duration}"
  if index_page != last_page_index
    listing_tables.pagination_button_click(index_page+1)
  end
end

puts 'finished'