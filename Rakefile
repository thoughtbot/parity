require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require File.expand_path("../lib/parity/version", __FILE__)

RSpec::Core::RakeTask.new('spec')

task default: :spec

PACKAGE_NAME = 'parity'
TRAVELING_RUBY_VERSION = '20141215-2.1.5'

namespace :package do
  desc "Generate parity #{Parity::VERSION} package for OSX"
  task osx: "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
    package_dir = "#{PACKAGE_NAME}-#{Parity::VERSION}-osx"

    rm_rf package_dir
    mkdir_p "#{package_dir}/lib/app"
    cp_r "lib", "#{package_dir}/lib/app"
    cp "README.md", "#{package_dir}/lib/app"

    mkdir "#{package_dir}/lib/app/bin"
    cp "bin/development", "#{package_dir}/lib/app/bin"
    cp "bin/staging", "#{package_dir}/lib/app/bin"
    cp "bin/production", "#{package_dir}/lib/app/bin"

    mkdir "#{package_dir}/bin"
    cp "packaging/shim.sh", "#{package_dir}/bin/development"

    mkdir_p "#{package_dir}/lib/ruby"
    sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz -C #{package_dir}/lib/ruby"

    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
  end
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
  sh "cd packaging && curl -L -O --fail " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"
end
