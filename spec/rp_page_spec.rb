# spec/rp_parser_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_page"

module Jekyll
  module RpLogs
    RSpec.describe Page do
      describe "methods and delegations" do
        subject do
          jekyll_page = instance_double("Jekyll::Page", data: {})
          Page.new(jekyll_page)
        end

        it { is_expected.to respond_to(:[]) }
        it { is_expected.to respond_to(:[]=) }
        it { is_expected.to respond_to(:content) }
        it { is_expected.to respond_to(:content=) }
        it { is_expected.to respond_to(:path) }
        it { is_expected.to respond_to(:to_liquid) }
        it { is_expected.to respond_to(:errors?) }
      end

      let(:val_tags) { { "rp_tags" => "tag 1, tag 2" } }
      let(:val_format) { { "format" => ["weechat"] } }
      let(:val_arc_name) { { "arc_name" => ["Story Arc"] } }
      let(:format_list) { { "weechat" => true } }

      let(:valid_page) do
        instance_double("Jekyll::Page",
                        data: [val_tags, val_format, val_arc_name].reduce(&:merge))
      end

      let(:page_no_tags) do
        instance_double("Jekyll::Page",
                        data: [val_format, val_arc_name].reduce(&:merge))
      end
      let(:wrong_arc) do
        instance_double("Jekyll::Page",
                        data: [val_tags, val_format, { "arc_name" => "Wrong" }].reduce(&:merge))
      end

      describe "initialize" do
        it "splits and converts a string listing tags to RpLogs::Tag objects" do
          expect(Page.new(valid_page)[:rp_tags].size).to eql(2)
        end
        it "does nothing to an empty tag string" do
          expect(Page.new(page_no_tags)[:rp_tags]).to be_nil
        end
      end

      describe ".errors?" do
        context "with malformed formats" do
          let(:nil_format) do
            instance_double("Jekyll::Page",
                            data: [val_tags, val_arc_name].reduce(&:merge))
          end
          let(:empty_format) do
            instance_double("Jekyll::Page",
                            data: [val_tags, val_arc_name, { "format" => [] }].reduce(&:merge))
          end

          it "catches a nil format" do
            expect(Page.new(nil_format).errors?({})).to be_truthy
          end
          it "catches an empty format list" do
            expect(Page.new(empty_format).errors?({})).to be_truthy
          end
          it "catches an unsupported format" do
            expect(Page.new(valid_page).errors?({})).to be_truthy
          end
        end

        it "catches empty tags" do
          expect(Page.new(page_no_tags).errors?(format_list)).to be_truthy
        end

        it "catches malformed arc_name" do
          expect(Page.new(wrong_arc).errors?(format_list)).to be_truthy
        end

        it "validates a page with no errors" do
          expect(Page.new(valid_page).errors?(format_list)).to be_falsey
        end
      end
    end
  end
end
