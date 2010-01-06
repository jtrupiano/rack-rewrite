require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rack-rewrite"
    gem.summary = %Q{A rack middleware for enforcing rewrite rules}
    gem.description = %Q{A rack middleware for enforcing rewrite rules. In many cases you can get away with rack-rewrite instead of writing Apache mod_rewrite rules.}
    gem.email = "jtrupiano@gmail.com"
    gem.homepage = "http://github.com/jtrupiano/rack-rewrite"
    gem.authors = ["John Trupiano"]
    gem.rubyforge_project = "johntrupiano"
    gem.add_development_dependency "shoulda"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rack-rewrite #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('History.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
