require 'spec_helper'

vcr_options = { :cassette_name => "models_triannon_annotation" }
describe Triannon::Annotation, :vcr => vcr_options do

  it "doesn't do external lookup of json_ld context" , :vcr => {:record => :none} do
    anno = Triannon::Annotation.new data: Triannon.annotation_fixture("bookmark.json")
    # NOTE:  VCR would throw an error if this does an external lookup
    # https://www.relishapp.com/vcr/vcr/v/2-9-3/docs/record-modes/none
    expect(anno.graph).to be_a_kind_of RDF::Graph
  end

  context 'json_ld replaces context url with inline context' do
    before(:each) do
      @json_b4_url = "{
                        \"@context\"  :     \""
      @json_after_url = "\"   ,
                        \"@id\": \"http://example.org/annos/annotation/foo.json\",
                        \"@type\": \"oa:Annotation\",
                        \"motivatedBy\": \"oa:bookmarking\",
                        \"hasTarget\": \"http://purl.stanford.edu/kq131cs7229\"
                      }"
      @inline_context = File.read "lib/triannon/oa_context_20130208.json"
    end
    it "http://www.w3.org/ns/oa-context-20130208.json as url" do
      data_w_url = @json_b4_url + "http://www.w3.org/ns/oa-context-20130208.json" + @json_after_url
      anno = Triannon::Annotation.new data: data_w_url
      anno.send(:json_ld)
      expect(anno.data).to include(@inline_context)
    end
    it "http://www.w3.org/ns/oa.json as url" do
      data_w_url = @json_b4_url + "http://www.w3.org/ns/oa.jsonld" + @json_after_url
      anno = Triannon::Annotation.new data: data_w_url
      anno.send(:json_ld)
      expect(anno.data).to include(@inline_context)
    end
  end

  context "data_as_graph" do
    before(:each) do
      @json_ld_data = Triannon.annotation_fixture("bookmark.json")
    end
    context "json-ld data" do
      it "populates graph from json-ld" do
        expect(@json_ld_data).to match(/\A\{.+\}\Z/m) # (Note:  \A and \Z and m are needed instead of ^$ due to \n in data)
        anno = Triannon::Annotation.new data: @json_ld_data
        expect(anno.graph).to be_a_kind_of RDF::Graph
        expect(anno.graph.count).to be > 1
      end
      it "is rejected if first and last non whitespace characters aren't { and }" do
        anno = Triannon::Annotation.new data: "xxx " + @json_ld_data
        expect(anno.graph).to be_nil
      end
      it "converts data to turtle" do
        anno = Triannon::Annotation.new data: @json_ld_data
        c = anno.graph.count
        g = RDF::Graph.new
        g.from_ttl(anno.data)
        expect(g.count).to eql c
      end
    end
    context "turtle data" do
      before(:each) do
        @ttl_data = Triannon.annotation_fixture("body-chars.ttl")
      end
      it "populates graph from ttl" do
        expect(@ttl_data).to match(/\.\Z/)  # (Note:  \Z is needed instead of $ due to \n in data)
        anno = Triannon::Annotation.new data: @ttl_data
        expect(anno.graph).to be_a_kind_of RDF::Graph
        expect(anno.graph.count).to be > 1
      end
      it "is rejected if it doesn't end in period" do
        anno = Triannon::Annotation.new data: @ttl_data + "xxx"
        expect(anno.graph).to be_nil
      end
    end
    context "rdf(xml) data" do
      before(:each) do
        @rdfxml_data = Triannon.annotation_fixture("body-chars.rdf")
      end
      it "populates graph from rdfxml" do
        expect(@rdfxml_data).to match(/\A<.+>\Z/m) # (Note:  \A and \Z and m are needed instead of ^$ due to \n in data)
        anno = Triannon::Annotation.new data: @rdfxml_data
        expect(anno.graph).to be_a_kind_of RDF::Graph
        expect(anno.graph.count).to be > 1
      end
      it "is rejected if first and last non whitespace characters aren't < and >" do
        anno = Triannon::Annotation.new data: "xxx " + @rdfxml_data
        expect(anno.graph).to be_nil
      end
    end
  end # data_as_graph

  context "parsing graph" do
    before(:each) do
      @anno_json = Triannon::Annotation.new data: Triannon.annotation_fixture("bookmark.json")
      @anno_ttl = Triannon::Annotation.new data: Triannon.annotation_fixture("body-chars.ttl")
    end
    it "type is oa:Annotation" do
      expect(@anno_ttl.type).to eql("http://www.w3.org/ns/oa#Annotation")
      expect(@anno_json.type).to eql("http://www.w3.org/ns/oa#Annotation")
      anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-targets.json")
      expect(anno.type).to eql("http://www.w3.org/ns/oa#Annotation")
    end
    it "url" do
      expect(@anno_json.url).to eql("http://example.org/annos/annotation/bookmark.json")
      expect(@anno_ttl.url).to eql("http://example.org/annos/annotation/body-chars.ttl")
      anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-targets.json")
      expect(anno.url).to eql("http://example.org/annos/annotation/mult-targets.json")
    end
    context "has_target" do
      it "single url" do
        expect(@anno_ttl.has_target[0]).to eql("http://purl.stanford.edu/kq131cs7229")
        expect(@anno_json.has_target).to include("http://purl.stanford.edu/kq131cs7229")
      end
      it "multiple urls" do
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-targets.json")
        expect(anno.has_target.size).to eql 2
        expect(anno.has_target).to include("http://purl.stanford.edu/kq131cs7229")
        expect(anno.has_target).to include("https://stacks.stanford.edu/image/kq131cs7229/kq131cs7229_05_0032_large.jpg")
      end
    end
    context "has_body" do
      it "empty array when there is no body" do
        expect(@anno_json.has_body).not_to be_nil
        expect(@anno_json.has_body.size).to eql 0
      end
      it "text from chars" do
        expect(@anno_ttl.has_body.size).to eql 1
        expect(@anno_ttl.has_body).to include("I love this!")
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("body-chars.json")
        expect(anno.has_body.size).to eql 1
        expect(anno.has_body).to include("I love this!")
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("body-chars-plain.json")
        expect(anno.has_body.size).to eql 1
        expect(anno.has_body).to include("I love this!")
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("body-chars-html.json")
        expect(anno.has_body.size).to eql 1
        expect(anno.has_body).to include("<div xml:lang='en' xmlns='http://www.w3.org/1999/xhtml'>I love this!</div>")
      end
      it "mult targets" do
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-targets.json")
        expect(anno.has_body.size).to eql 1
        expect(anno.has_body).to include("I love these two things!")
      end
    end
    context "motivated_by" do
      it "single" do
        expect(@anno_ttl.motivated_by.size).to eql 1
        expect(@anno_ttl.motivated_by[0]).to eql("http://www.w3.org/ns/oa#commenting")
        expect(@anno_json.motivated_by.size).to eql 1
        expect(@anno_json.motivated_by).to include("http://www.w3.org/ns/oa#bookmarking")
      end
      it "multiple" do
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-motivations.json")
        expect(anno.motivated_by.size).to eql 2
        expect(anno.motivated_by).to include("http://www.w3.org/ns/oa#moderating")
        expect(anno.motivated_by).to include("http://www.w3.org/ns/oa#tagging")
      end
      it "mult targets" do
        anno = Triannon::Annotation.new data: Triannon.annotation_fixture("mult-targets.json")
        expect(anno.motivated_by.size).to eql 1
        expect(anno.motivated_by).to include("http://www.w3.org/ns/oa#commenting")
      end
    end
  end # parsing graph

  context ".all" do
    it "returns an array of all Annotation identifiers in the repository" do
      root_anno_ttl = File.read(Triannon.fixture_path("ldp_annotations") + '/fcrepo4_root_anno_container.ttl')
      allow_any_instance_of(Triannon::LdpLoader).to receive(:get_ttl).and_return(root_anno_ttl)
      results = Triannon::Annotation.all
      expect(results).to be_an_instance_of Array
      expect(results[0]).to be_an_instance_of Triannon::Annotation
      expect(results[0].id).to be_an_instance_of String
      # result only contains populated id attribute
      expect(results[0].url).to eql nil
      expect(results[0].type).to eql nil
    end
    it "calls LdpLoader.find_all" do
      expect_any_instance_of(Triannon::LdpLoader).to receive(:find_all)
      Triannon::Annotation.all
    end
  end

  context "#destroy" do

    it "calls LdpDestroyer.destroy with it's own id" do
      id = 'someid'

      expect(Triannon::LdpDestroyer).to receive(:destroy).with(id)
      a = Triannon::Annotation.new :id => id
      a.destroy
    end
  end

end
