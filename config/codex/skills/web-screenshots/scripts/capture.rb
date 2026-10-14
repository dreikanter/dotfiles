# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require 'timeout'

module WebScreenshots
  class HTTPError < StandardError; end

  class Session
    attr_reader :browser, :step

    def initialize(width: 1440, height: 1100, timeout: 45, browser_path: ENV['BROWSER_PATH'], insecure: false)
      require 'ferrum'
      @timeout = timeout
      @step = 'launch browser'
      options = { headless: true, window_size: [width, height], timeout: timeout }
      options[:browser_path] = browser_path if browser_path
      options[:browser_options] = { 'ignore-certificate-errors' => nil } if insecure
      @browser = Ferrum::Browser.new(**options)
      @browser.resize(width: width, height: height)
    end

    def wait(label)
      @step = label
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
      until yield
        raise Timeout::Error, "Timed out: #{label}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleep 0.1
      end
    end

    def navigate(url, ready_selector: nil, ready_text: nil)
      @step = 'navigate'
      browser.go_to(url)
      status = browser.network.status
      raise HTTPError, status.to_s if status && status >= 400

      wait('document readiness') { browser.evaluate('document.readyState !== "loading" && !!document.body') }
      wait('visible ready element') { visible?(ready_selector) } if ready_selector
      if ready_text
        wait('ready text') { browser.evaluate('document.body.innerText.includes(arguments[0])', ready_text) }
      end
    end

    def save(path, width: nil, height: nil, selector: nil, full: false, stabilize: true)
      raise ArgumentError, 'Choose an element or full page' if selector && full
      raise ArgumentError, 'Supply both width and height' if !!width != !!height

      @step = 'prepare screenshot'
      FileUtils.mkdir_p(File.dirname(path))
      browser.resize(width: width, height: height) if width
      if selector
        wait('visible capture element') { visible?(selector) }
        browser.execute('document.querySelector(arguments[0]).scrollIntoView({block: "center", behavior: "instant"})', selector)
      end
      browser.execute(<<~JS) if stabilize
        const style = document.createElement('style');
        style.id = 'web-screenshots-stability';
        style.textContent = '*, *::before, *::after { animation: none !important; transition: none !important; caret-color: transparent !important; scroll-behavior: auto !important; }';
        document.head.appendChild(style);
      JS
      @step = 'fonts and images'
      browser.evaluate_async('document.fonts.ready.then(() => arguments[0](true))', @timeout)
      wait('images in capture area') do
        browser.evaluate(<<~JS, selector, full)
          (() => {
            const root = arguments[0] ? document.querySelector(arguments[0]) : document;
            const images = [...root.querySelectorAll('img')];
            if (root.tagName === 'IMG') images.push(root);
            return images.every(img => {
              const r = img.getBoundingClientRect();
              const relevant = r.width && r.height && (arguments[0] || arguments[1] || (r.bottom > 0 && r.top < innerHeight && r.right > 0 && r.left < innerWidth));
              return !relevant || (img.complete && img.naturalWidth > 0);
            });
          })()
        JS
      end
      browser.evaluate_async('requestAnimationFrame(() => requestAnimationFrame(() => arguments[0](true)))', @timeout)
      @step = 'write screenshot'
      browser.screenshot(path: path, full: full, selector: selector)
      metrics = browser.evaluate('({width: innerWidth, height: innerHeight, horizontal_overflow: document.documentElement.scrollWidth > innerWidth})')
      puts JSON.generate(path: File.expand_path(path), viewport: metrics, full_page: full, element: selector)
    ensure
      begin
        browser&.execute('document.getElementById("web-screenshots-stability")?.remove()') if stabilize
      rescue StandardError
        # Preserve the original failure if the browser has disconnected.
      end
    end

    private

    def visible?(selector)
      browser.evaluate(<<~JS, selector)
        (() => {
          const el = document.querySelector(arguments[0]);
          if (!el) return false;
          const r = el.getBoundingClientRect();
          const style = getComputedStyle(el);
          return r.width > 0 && r.height > 0 && style.visibility !== 'hidden' && style.opacity !== '0';
        })()
      JS
    end
  end

  def self.run(error_path:, **options)
    session = Session.new(**options)
    yield session
    true
  rescue StandardError, LoadError => error
    artifact = nil
    begin
      if session&.browser
        FileUtils.mkdir_p(File.dirname(error_path))
        session.browser.screenshot(path: error_path)
        artifact = File.expand_path(error_path)
      end
    rescue StandardError
      # The browser may already be unavailable after a navigation failure.
    end
    details = { error: error.class.name, step: session&.step || 'launch browser', screenshot: artifact }
    details[:http_status] = error.message.to_i if error.is_a?(HTTPError)
    warn JSON.generate(details)
    false
  ensure
    session&.browser&.quit
  end
end

if $PROGRAM_NAME == __FILE__
  options = { width: 1440, height: 1100, timeout: 45, full: false, stabilize: true }
  parser = OptionParser.new do |flags|
    flags.banner = 'Usage: ruby capture.rb --url URL --output FILE.png [options]'
    flags.on('--url URL') { |value| options[:url] = value }
    flags.on('--output PATH') { |value| options[:output] = value }
    flags.on('--ready-selector CSS') { |value| options[:ready_selector] = value }
    flags.on('--ready-text TEXT') { |value| options[:ready_text] = value }
    flags.on('--selector CSS') { |value| options[:selector] = value }
    flags.on('--full-page') { options[:full] = true }
    flags.on('--keep-animations') { options[:stabilize] = false }
    flags.on('--browser PATH') { |value| options[:browser_path] = value }
    flags.on('--insecure') { options[:insecure] = true }
    flags.on('--timeout SECONDS', Integer) { |value| options[:timeout] = value }
    flags.on('--viewport WIDTHxHEIGHT', /\A[1-9]\d*x[1-9]\d*\z/) do |value|
      options[:width], options[:height] = value.split('x').map(&:to_i)
    end
    flags.on('-h', '--help') { puts flags; exit }
  end
  begin
    parser.parse!
    raise OptionParser::MissingArgument, '--url and --output are required' unless options[:url] && options[:output]
    raise OptionParser::InvalidArgument, '--timeout must be positive' unless options[:timeout].positive?
    raise OptionParser::InvalidArgument, '--selector and --full-page conflict' if options[:selector] && options[:full]
    raise OptionParser::InvalidArgument, 'Unexpected positional arguments' unless ARGV.empty?
  rescue OptionParser::ParseError => error
    warn error.message
    warn parser
    exit 2
  end
  output = options.delete(:output)
  url = options.delete(:url)
  readiness = { ready_selector: options.delete(:ready_selector), ready_text: options.delete(:ready_text) }
  capture = { selector: options.delete(:selector), full: options.delete(:full), stabilize: options.delete(:stabilize) }
  ok = WebScreenshots.run(error_path: output.sub(/\.png\z/i, '') + '.error.png', **options) do |session|
    session.navigate(url, **readiness)
    session.save(output, **capture)
  end
  exit(ok ? 0 : 1)
end
