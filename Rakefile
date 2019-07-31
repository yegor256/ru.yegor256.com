# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'tempfile'
require 'rake/clean'
require 'scss_lint/rake_task'
require 'w3c_validators'
require 'nokogiri'
require 'rubocop/rake_task'
require 'English'
require 'net/http'
require 'html-proofer'

task default: [
  :clean,
  :build,
  :scss_lint,
  :pages,
  :garbage,
  # :ping,
  :orphans,
  :rubocop
]

def done(msg)
  puts msg + "\n\n"
end

desc 'Delete _site directory'
task :clean do
  rm_rf '_site'
  done 'Jekyll site directory deleted'
end

desc 'Lint SASS sources'
SCSSLint::RakeTask.new do |t|
  f = Tempfile.new(['bloghacks-', '.scss'])
  f << File.open('css/main.scss').drop(2).join("\n")
  f.flush
  f.close
  t.files = Dir.glob([f.path])
end

desc 'Build Jekyll site'
task :build do
  if File.exist? '_site'
    done 'Jekyll site already exists in _site'
  else
    system('jekyll build')
    raise 'Jekyll failed' unless $CHILD_STATUS.success?
    done 'Jekyll site generated without issues'
  end
end

desc 'Check the existence of all critical pages'
task pages: [:build] do
  File.open('_rake/pages.txt').map(&:strip).each do |p|
    file = "_site/#{p}"
    raise "Page #{file} is not found" unless File.exist? file
    puts "#{file}: OK"
  end
  done 'All files are in place'
end

desc 'Check the absence of garbage'
task garbage: [:build] do
  File.open('_rake/garbage.txt').map(&:strip).each do |p|
    file = "_site/#{p}"
    raise "Page #{file} is still there" if File.exist? file
    puts "#{file}: absent, OK"
  end
  done 'There is no garbage'
end

desc 'Validate a few pages for W3C compliance'
# It doesn't work now, because of: https://github.com/alexdunae/w3c_validators/issues/16
task w3c: [:build] do
  include W3CValidators
  validator = MarkupValidator.new
  [
    'index.html',
    '2016/09/12/first-post.html'
  ].each do |p|
    file = "_site/#{p}"
    results = validator.validate_file(file)
    if results.errors.empty?
      results.errors.each do |err|
        puts err.to_s
      end
      raise "Page #{file} is not W3C compliant"
    end
    puts "#{p}: OK"
  end
  done 'HTML is W3C compliant'
end

desc 'Ping all foreign links'
task ping: [:build] do
  links = Dir['_site/**/*.html'].reduce([]) do |array, f|
    array + Nokogiri::HTML(File.read(f)).xpath(
      '//a/@href[starts-with(.,"http://") or starts-with(.,"https://")]'
    ).to_a.map(&:to_s)
  end.uniq
  links.map { |u| URI.parse(u) }.each do |uri|
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.port == 443
    data = http.head(uri.request_uri, 'User-Agent' => 'ru.yegor256.com')
    puts "#{uri}: #{data.code}"
    raise "URI #{uri} is not OK" unless data.code == '200'
  end
  done 'All links are valid'
end

desc 'Make sure there are no orphan articles'
task orphans: [:build] do
  links = Dir['_site/**/*.html'].reduce([]) do |array, f|
    array + Nokogiri::HTML(File.read(f)).xpath('//a/@href').to_a.map(&:to_s)
  end
  links = links
    .map { |a| a.gsub(%r{^/}, 'http://bloghacks.yegor256.com/') }
    .select { |a| a.start_with? 'http://bloghacks.yegor256.com/' }
    .map { |a| a.gsub(/#.*/, '') }
  links += Dir['_site/**/*.html']
    .map { |f| f.gsub(/_site/, 'http://bloghacks.yegor256.com') }
  counts = {}
  links
    .select { |a| a.match %r{.*/[0-9]{4}/[0-9]{2}/[0-9]{2}/.*} }
    .group_by(&:itself).each { |k, v| counts[k] = v.length }
  orphans = 0
  counts.each do |k, v|
    if v < 3
      puts "#{k} is an orphan (#{v})"
      orphans += 1
    else
      puts "#{k}: #{v}"
    end
  end
  raise "There are #{orphans} orphans" unless orphans.zero?
  done "There are no orphans in #{links.size} links"
end

desc 'Run RuboCop on all Ruby files'
RuboCop::RakeTask.new do |t|
  t.fail_on_error = true
  t.requires << 'rubocop-rspec'
end
