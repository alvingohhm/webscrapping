require 'watir'

@driver_path_chrome = File.join(File.absolute_path('.', File.dirname(__FILE__)),"browsers","chromedriver.exe")

# @proxy_name = 'us-wa.proxymesh.com'
@proxy_name = 'sg.proxymesh.com'
@proxy_port = 'Enter port no here'

Selenium::WebDriver::Chrome.driver_path = @driver_path_chrome

url = "https://whatismyipaddress.com/"

full_proxy_config = "--proxy-server=#{@proxy_name}:#{@proxy_port}"
browser = Watir::Browser.new :chrome, :switches => [full_proxy_config]
browser.goto url
puts "finished"