require 'watir'

class BrowserController
  attr_accessor :url, :browser, :proxy_name, :proxy_port
  attr_reader :driver_path_chrome, :driver_path_firefox, :browser_type, :browser_use_proxy


  def initialize (chrome_browser = true, use_proxy = false)
    @browser_type = chrome_browser
    @browser_use_proxy = use_proxy
    @driver_path_chrome = File.join(File.absolute_path('..', File.dirname(__FILE__)),"browsers","chromedriver.exe")
    # @driver_path_firefox = File.join(File.absolute_path('..', File.dirname(__FILE__)),"browsers","geckodriver.exe")

    # @proxy_name = 'us-wa.proxymesh.com'
    # random_boolean = [true, false].sample
    @proxy_name = ['us-wa.proxymesh.com','open.proxymesh.com','sg.proxymesh.com']
    @proxy_port = 'Enter port no here'

    # @proxy_name = 'sg.proxymesh.com'


  end

  def open_browser (proxy_selection)
    if self.browser_type
      Selenium::WebDriver::Chrome.driver_path = driver_path_chrome
      if self.browser_use_proxy
        proxy_name_final = self.proxy_name[proxy_selection]
        full_proxy_config = "--proxy-server=#{proxy_name_final}:#{proxy_port}"
        self.browser = Watir::Browser.new :chrome, :switches => [full_proxy_config]
      else
        self.browser = Watir::Browser.new
      end
    else
      Selenium::WebDriver::Firefox.driver_path = driver_path_firefox
      if self.browser_use_proxy
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile['network.proxy.http'] = self.proxy_name[proxy_selection]
        profile['network.proxy.http_port'] = self.proxy_port.to_i
        profile['network.proxy.ftp'] = self.proxy_name[proxy_selection]
        profile['network.proxy.ftp_port'] = self.proxy_port.to_i
        profile['network.proxy.socks'] = self.proxy_name[proxy_selection]
        profile['network.proxy.socks_port'] = self.proxy_port.to_i
        profile['network.proxy.ssl'] = self.proxy_name[proxy_selection]
        profile['network.proxy.ssl_port'] = self.proxy_port.to_i
        profile['network.proxy.type'] = 1
        profile['network.proxy.share_proxy_settings'] = true
        profile['network.proxy.socks_remote_dns'] = true
        profile['devtools.jsonview.enabled'] = false
      else
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile['devtools.jsonview.enabled'] = false
      end
      self.browser = Watir::Browser.new :firefox, :profile => profile
    end
    self.browser.goto url
  end

  def browser_wait(second_delay)
    sleep second_delay
  end

  def browser_wait_until_present (xpath_string, second_delay)
    begin
      self.browser.element(xpath: xpath_string).wait_until_present
    rescue
      browser_wait (second_delay)
    end
  end
end
