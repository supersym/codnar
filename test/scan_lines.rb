require "codnar"
require "test/spec"
require "fakefs/safe"

module Codnar

  # Test scanning classified lines.
  class TestScanLines < Test::Unit::TestCase

    def setup
      @errors = Errors.new
      FakeFS.activate!
      FakeFS::FileSystem.clear
    end

    def teardown
      FakeFS.deactivate!
    end

    def test_scan_lines
      File::open("comments", "w") { |file| file.write(INPUT) }
      scanner = Scanner.new(@errors, SYNTAX)
      scanner.lines("comments").should == LINES
      @errors.should == ERRORS
    end

    SYNTAX = {
      "start_state" => "comment",
      "patterns" => {
        "shell" => { "regexp" => "^#+\s*(.*)$", "groups" => [ "comment" ] },
        "c++" => { "regexp" => /^\/\/+\s*(.*)$/, "groups" => [ "comment" ] },
        "invalid" => { "regexp" => "(" }
      },
      "states" => {
        "comment" => {
          "transitions" => [
            { "pattern" => "shell", "next_state" => "comment" },
            { "pattern" => "c++", "next_state" => "comment" },
            { "pattern" => "no-such-pattern", "next_state" => "no-such-state" },
          ]
        }
      }
    }

    INPUT = <<-EOF.unindent
      # foo
      // bar
      baz
    EOF

    LINES = [ {
      "kind" => "comment",
      "line" => "# foo\n",
      "comment" => "foo",
      "location" => { "file" => "comments", "line" => 1 },
    }, {
      "kind" => "comment",
      "line" => "// bar\n",
      "comment" => "bar",
      "location" => { "file" => "comments", "line" => 2 },
    }, {
      "kind" => "error",
      "line" => "baz\n",
      "state" => "comment",
      "location" => { "file" => "comments", "line" => 3 },
    } ]

    ERRORS = [
      "#{$0}: Invalid pattern: invalid regexp: ( error: premature end of regular expression: /(/",
      "#{$0}: Reference to a missing pattern: no-such-pattern",
      "#{$0}: Reference to a missing state: no-such-state",
      "#{$0}: State: comment failed to classify line: baz in file: comments at line: 3"
    ]

  end

end