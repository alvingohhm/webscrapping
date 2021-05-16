require './lib/listing_summary'
require './lib/listing_content'
require 'fileutils'

# ListingSummary.new(property_type) ["hdb", "condo", "landed"]
listing_summaries = ListingSummary.new(1)
listing_summaries.create_summary_csv #remember to change if do not want to wipe of existing csv data

# ListingContent.new(base_directory, property_type, logfile)
listing_contents = ListingContent.new(listing_summaries.base_directory, listing_summaries.property_type, listing_summaries.log_trace)
listing_contents.create_csvs

listing_summaries.get_all_index_page
listing_summaries.log_trace.write_header = "Start of Extraction Process - Processing a Total of #{listing_summaries.index_page_lists.size} Pages"
page_no = 0
listing_summaries.index_page_lists.each do |index_page|
  page_no += 1
  puts "processing Page #{page_no}"
  listing_summaries.log_trace.write_section = "Extraction Data from Page #{page_no}"
  listing_summaries.parse_index_page(index_page, page_no)
  listing_summaries.get_all_listing #to write summary data for every listing and also collect all the content folder
  if not listing_summaries.listing_folders.empty? #check is there a list of folder to loop to collect content
    listing_contents.clear_data_rows
    listing_summaries.listing_folders.each do |listing_folder|
      if listing_contents.duplicate_listing_content?(listing_folder, "Done")
        next
      end
      search_directory = listing_folder + "*"
      content_files = Dir[search_directory]
      if not content_files.empty?
        content_files.each do |content_file|
          content_file_name = content_file.split('/').last
          case content_file_name
            when "listing.html"
              listing_contents.process_details_content(content_file)
            when /Commute/
              listing_contents.process_commute_content(content_file)
            when /transaction_history/
              listing_contents.process_transaction_history_content(content_file)
            else
              listing_contents.process_places_content(content_file)
          end
        end
      end
      listing_contents.create_checking_folder(listing_folder, "Done")
    end
    listing_contents.write_data_rows
  end
  # listing_summaries.archive_index_page(index_page, "Done")
  puts "End of processing Page #{page_no}"
  listing_summaries.log_trace.write_section = "End of Extraction Data from Page #{page_no}"
end
listing_summaries.log_trace.write_header = "End of Extraction Process - Processing a Total of #{listing_summaries.index_page_lists.size} Pages"
puts "finished"