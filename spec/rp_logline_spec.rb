# spec/rp_logline_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_logline"

module Jekyll
  module RpLogs
    RSpec.describe LogLine do
      describe "attributes" do
        let(:alice_line) do
          LogLine.new(
            DateTime.new(2015, 9, 23, 14, 35, 27, "-4"),
            sender: "Alice",
            contents: "Lorem ipsum dolor sit amet, consectetur adipisicing elit.",
            flags: "",
            type: :rp
          )
        end
        subject { alice_line }

        it { is_expected.to respond_to(:timestamp) }
        it { is_expected.to respond_to(:mode) }
        it { is_expected.to respond_to(:sender) }
        it { is_expected.to respond_to(:contents) }
        it { is_expected.to respond_to(:flags) }
        it { is_expected.to respond_to(:base_type) }
        it { is_expected.to respond_to(:output_type) }

        context "without arguments" do
          describe ".mode" do
            it "returns \" \"" do
              expect(alice_line.mode).to eql(" ")
            end
          end
        end
      end

      # Test the proper classification of lines as RP or OOC for output, based
      # on various properties: the strict_ooc option, beginning with parens,
      # and any flags specified
      before :context do
        @timestamp = DateTime.new(2015, 9, 23, 14, 35, 27, "-4")
        @rp_contents = "Lorem ipsum dolor sit amet, consectetur adipisicing elit."
        @ooc_contents = "(Lorem ipsum dolor sit amet, consectetur adipisicing elit.)"
      end

      def log_line(timestamp: @timestamp, options: {}, sender: "Alice", contents: @rp_contents, flags: "", type: :rp)
        LogLine.new(timestamp, options, sender: sender, contents: contents, flags: flags, type: type)
      end

      def strict_log_line(timestamp: @timestamp, options: { strict_ooc: true }, sender: "Alice", contents: @rp_contents, flags: "", type: :rp)
        LogLine.new(timestamp, options, sender: sender, contents: contents, flags: flags, type: type)
      end

      let(:rp_line) { log_line }
      let(:ooc_line) { log_line(contents: @ooc_contents, type: :ooc) }
      let(:rp_flag) { log_line(contents: @ooc_contents, flags: LogLine::RP_FLAG, type: :ooc) }
      let(:ooc_flag) { log_line(flags: LogLine::OOC_FLAG) }
      let(:invalid_type) { log_line(type: :not_a_type) }

      describe "#initialize" do
        let(:whitespace_line) { log_line(contents: "  ", type: :ooc) }

        it "does not crash on lines that are entirely whitespace" do
          expect(whitespace_line.output_type).to eql(:ooc)
        end
      end

      describe "#output_type" do
        context "with :strict_ooc option" do
          let(:strict_ooc_default) { strict_log_line(type: :ooc) }
          let(:strict_ooc_ooc) { strict_log_line(contents: @ooc_contents, type: :ooc) }

          it "is RP without open paren" do
            expect(strict_ooc_default.output_type).to eql(:rp)
          end
          it "is OOC with open paren" do
            expect(strict_ooc_ooc.output_type).to eql(:ooc)
          end
          it "is OOC with open bracket" do
            expect(strict_log_line(contents: "[Lorem ipsum").output_type).to eql(:ooc)
          end

          context "with flags" do
            let(:strict_rp_flag) { strict_log_line(contents: @ooc_contents, flags: LogLine::RP_FLAG, type: :ooc) }
            let(:strict_ooc_flag) { strict_log_line(flags: LogLine::OOC_FLAG) }

            it "is RP with !RP flag" do
              expect(strict_rp_flag.output_type).to eql(:rp)
            end
            it "is OOC with !OOC flag" do
              expect(strict_ooc_flag.output_type).to eql(:ooc)
            end
          end
        end

        context "without :strict_ooc option" do
          it "is RP when originally RP" do
            expect(rp_line.output_type).to eql(:rp)
          end
          it "is OOC when originally OOC" do
            expect(ooc_line.output_type).to eql(:ooc)
          end
          it "is RP with !RP flag" do
            expect(rp_flag.output_type).to eql(:rp)
          end
          it "is OOC with !OOC flag" do
            expect(ooc_flag.output_type).to eql(:ooc)
          end

          let(:rp_line_with_paren) { log_line(contents: @ooc_contents) }
          let(:rp_line_with_bracket) { log_line(contents: "[Lorem ipsum") }

          it "is OOC with open paren" do
            expect(rp_line_with_paren.output_type).to eql(:ooc)
          end
          it "is OOC with open bracket" do
            expect(rp_line_with_bracket.output_type).to eql(:ooc)
          end
        end
      end

      describe "#output_timestamp" do
        # This feels like a bad test :S
        it "combines anchor, title, and display" do
          expect(rp_line.output_timestamp).to eql("<a name=\"#{@timestamp.strftime('%Y-%m-%d_%H:%M:%S')}\" title=\"#{@timestamp.strftime('%H:%M:%S %B %-d, %Y')}\" href=\"##{@timestamp.strftime('%Y-%m-%d_%H:%M:%S')}\">#{@timestamp.strftime('%H:%M')}</a>")
        end
      end

      describe ".output_sender" do
        it "diplays RP senders correctly" do
          expect(rp_line.output_sender).to eql("  * Alice")
          expect(ooc_flag.output_sender).to eql("  * Alice")
        end
        it "displays OOC senders correctly" do
          expect(ooc_line.output_sender).to eql(" &lt; Alice&gt;")
          expect(rp_flag.output_sender).to eql(" &lt; Alice&gt;")
        end
        context "when given a nonexistent base_type" do
          it "raises a 'No known type' error" do
            expect { invalid_type.output_sender }.to raise_exception("No known type: not_a_type")
          end
        end
      end

      describe "#output_tags" do
        it "outputs .rp when given RP output type" do
          expect(rp_line.output_tags).to eql(['<p class="rp">', "</p>"])
        end
        it "outputs .ooc when given OOC output type" do
          expect(ooc_line.output_tags).to eql(['<p class="ooc">', "</p>"])
        end
        context "when given a nonexistent output_type" do
          it "raises a 'No known type' error" do
            expect { invalid_type.output_tags }.to raise_exception("No known type: not_a_type")
          end
        end
      end

      describe "#output" do
        context "when called" do
          subject { rp_line }
          it { is_expected.to receive(:output_tags) }
          it { is_expected.to receive(:output_timestamp) }
          it { is_expected.to receive(:output_sender) }
          after { subject.output }
        end
        context "when called with HTML special characters" do
          subject { log_line(contents: "Foo & Bar \"baz\" <horse>").output }
          it "escapes them" do
            expect(subject).to include("Foo &amp; Bar &quot;baz&quot; &lt;horse&gt;")
          end
        end
      end

      let(:merge_content_1) { "The quick brown fox" }
      let(:merge_content_2) { "jumps over the lazy dog" }

      # def add_seconds(line, secs)
      #   LogLine.new(
      #     line.timestamp + Rational(secs, 60 * 60 * 24),
      #     line.options,
      #     sender: line.sender,
      #     contents: line.contents,
      #     flags: line.flags.join(" "),
      #     type: line.base_type,
      #     mode: line.mode)
      # end

      def add_seconds(date, secs)
        date + Rational(secs, 60 * 60 * 24)
      end

      let(:merged_content) { "#{merge_content_1} #{merge_content_2}" }
      let(:line_1) { log_line(contents: merge_content_1) }
      let(:line_2) { log_line(timestamp: add_seconds(line_1.timestamp, LogLine.max_seconds_between_posts), contents: merge_content_2) }
      let(:merged_line) do
        line_1.merge! line_2
      end

      describe ".merge!" do
        it "appends the contents of the next line" do
          expect(merged_line.contents).to eql(merged_content)
        end
        it "updates last_merged_timestamp" do
          expect(merged_line.last_merged_timestamp).to eql(line_2.timestamp)
        end
        it "returns itself" do
          temp_var = line_1
          expect(temp_var.merge! line_2).to equal(line_1)
        end

        context "with splits_by_character option" do
          let(:sbc_1) { log_line(contents: "Sesquip", options: { splits_by_character: ["Alice"] }) }
          let(:sbc_2) { log_line(contents: "edalian", options: { splits_by_character: ["Alice"] }) }

          it "doesn't add a space" do
            expect(sbc_1.merge!(sbc_2).contents).to eql("Sesquipedalian")
          end
        end
      end

      describe "#mergeable_with?" do
        context "when lines meet all requirements" do
          it { expect(line_1.mergeable_with? line_2).to be true }
        end

        let(:future_line) { log_line(timestamp: add_seconds(@timestamp, LogLine.max_seconds_between_posts+1)) }
        context "when the timestamp difference is too large" do
          it { expect(line_1.mergeable_with? future_line).to be_falsey }
        end
        context "when the timestamp difference is negative" do
          it { expect(line_2.mergeable_with? line_1).to be_falsey }
        end
        context "with different senders" do
          it { expect(line_1.mergeable_with? log_line(sender: "Bob")).to be_falsey }
        end
        context "with a non-:rp output_type for the first line" do
          it { expect(log_line(type: :ooc).mergeable_with? line_2).to be_falsey }
        end
        context "with a non-:rp output_type for the second line" do
          it { expect(line_1.mergeable_with? log_line(type: :ooc)).to be_falsey }
          context "when the sender splits to normal text" do
            let(:split_to_normal) { log_line(type: :ooc, options: { merge_text_into_rp: ["Alice"] }) }
            it { expect(line_1.mergeable_with? split_to_normal).to be true }
          end
        end

        context "when given override flags" do
          def add_flag(line, flag)
            LogLine.new(
              line.timestamp,
              line.options,
              sender: line.sender,
              contents: line.contents,
              flags: flag,
              type: line.base_type,
              mode: line.mode)
          end

          def add_merge_flag(line)
            add_flag(line, LogLine::MERGE_FLAG)
          end

          def add_split_flag(line)
            add_flag(line, LogLine::SPLIT_FLAG)
          end

          context "when given !MERGE" do
            it "is true for all kinds of invalid tests" do
              expect(line_1.mergeable_with? add_merge_flag(future_line)).to be true
              expect(line_2.mergeable_with? add_merge_flag(line_1)).to be true
              expect(line_1.mergeable_with? add_merge_flag(log_line(sender: "Bob"))).to be true
              expect(log_line(type: :ooc).mergeable_with? add_merge_flag(line_2)).to be true
              expect(line_1.mergeable_with? add_merge_flag(log_line(type: :ooc))).to be true
            end
          end
          context "when given !SPLIT" do
            it "doesn't merge even acceptable lines" do
              expect(line_1.mergeable_with? add_split_flag(line_2)).to be_falsey
            end
          end
        end
      end

      describe "#inspect" do
        it "returns a string" do
          expect(rp_line.inspect).to be_instance_of(String)
        end
      end
    end
  end
end
