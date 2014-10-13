require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Triannon::Annotation do
  include ActiveModel::Lint::Tests

    # to_s is to support ruby-1.9
    ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
      example m.gsub('_',' ') do
        send m
      end
    end

    def model
      subject
    end
end