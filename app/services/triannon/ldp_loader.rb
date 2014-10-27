
module Triannon

  # Loads an existing Annotation from the LDP server
  class LdpLoader

    def self.load key
      l = Triannon::LdpLoader.new key
      l.load_annotation
      l.load_body
      l.load_target

      oa_graph = Triannon::LdpToOaMapper.ldp_to_oa l.annotation
      oa_graph
    end

    def self.find_all
      l = Triannon::LdpLoader.new
      l.find_all
    end

    attr_accessor :annotation

    def initialize key = nil
      @key = key
      @base_uri = Triannon.config[:ldp_url]
      @annotation = Triannon::AnnotationLdp.new
    end

    def load_annotation
      @annotation.load_data_into_graph get_ttl @key
    end

    def load_body
      if @annotation.body_uri
        uri = @annotation.body_uri.to_s
        sub_path = uri.split(@base_uri + '/').last
        @annotation.load_data_into_graph get_ttl sub_path
      end
    end

    def load_target
      uri = @annotation.target_uri.to_s
      sub_path = uri.split(@base_uri + '/').last
      @annotation.load_data_into_graph get_ttl sub_path
    end

    # @return [Array<Triannon::Annotation>] an array of Triannon::Annotation objects with just the id set. Enough info to build the index page
    def find_all
      root_ttl = get_ttl
      objs = []

      g = RDF::Graph.new
      g.from_ttl root_ttl
      root_uri = RDF::URI.new @base_uri
      results = g.query [root_uri, RDF::LDP.contains, nil]
      results.each do |stmt|
        id = stmt.object.to_s.split('/').last
        objs << Triannon::Annotation.new(:id => id)
      end

      objs
    end

    protected

    def get_ttl sub_path = nil
      resp = conn.get do |req|
        req.url "#{sub_path}" if sub_path
        req.headers['Accept'] = 'text/turtle'
      end
      resp.body
    end

    def conn
      @c ||= Faraday.new @base_uri
    end

  end


end
