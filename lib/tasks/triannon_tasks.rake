require_relative '../../app/services/triannon/ldp_writer'

namespace :triannon do
  desc "set up jetty for triannon"
  task :jetty_setup => [:solr_jetty_setup, :disable_fedora_auth_in_jetty]

  desc "set up triannon Solr in jetty"
  task :solr_jetty_setup do
    `cp -r config/solr/triannon-core jetty/solr`
    `cp config/solr/solr.xml jetty/solr`
  end

  desc "disable fedora basic authorization in jetty"
  task :disable_fedora_auth_in_jetty do
    `cp config/jetty/etc/* jetty/etc`
  end

  desc 'Create the uber root annotation container'
  task :create_uber_root_container do
    unless File.exist? Triannon.triannon_file
      puts "Triannon config file missing: #{Triannon.triannon_file}"
    end
    Triannon::LdpWriter.create_basic_container(nil, Triannon.config[:ldp]['uber_container'])
  end
end
