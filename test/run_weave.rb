require "codnar"
require "test/spec"
require "fakefs/safe"

module Codnar

  # Test running the Weave Codnar Application.
  class TestRunWeave < Test::Unit::TestCase

    def setup
      FakeFS.activate!
      FakeFS::FileSystem.clear
    end

    def teardown
      FakeFS.deactivate!
    end

    def test_print_help
      run_with_argv(%w(-h -o stdout)) { Weave.new(true).run }.should == 0
      help = File.read("stdout")
      [ "codnar-weave", "OPTIONS", "DESCRIPTION" ].each { |text| help.should.include?(text) }
    end

    def test_run_weave
      File.open("root", "w") { |file| file.write(ROOT_CHUNKS.to_yaml) }
      File.open("included", "w") { |file| file.write(INCLUDED_CHUNKS.to_yaml) }
      run_with_argv(%w(-o stdout root included)) { Weave.new(true).run }.should == 0
      File.read("stdout").should == "Root\nIncluded\n"
    end

    def test_run_weave_missing_chunk
      File.open("root", "w") { |file| file.write(ROOT_CHUNKS.to_yaml) }
      run_with_argv(%w(-e stderr -o stdout root)) { Weave.new(true).run }.should == 1
      File.read("stderr").should == "#{$0}: Missing chunk: included in file: root\n"
    end

#   def test_run_weave_unused_chunk
#     File.open("root", "w") { |file| file.write(ROOT_CHUNKS.to_yaml) }
#     File.open("included", "w") { |file| file.write(INCLUDED_CHUNKS.to_yaml) }
#     run_with_argv(%w(-e stderr -o stdout included root)) { Weave.new(true).run }.should == 1
#     File.read("stderr").should == "#{$0}: Missing chunk: included in file: root\n"
#   end

  protected

    def run_with_argv(argv)
      return Globals.without_changes do
        ARGV.replace(argv)
        yield
      end
    end

    ROOT_CHUNKS = [ {
      "name" => "root",
      "locations" => [ { "file" => "root", "line" => 1 } ],
      "html" => "Root\n<script src='included' type='x-codnar/include'></script>"
    } ]

    INCLUDED_CHUNKS = [ {
      "name" => "included",
      "locations" => [ { "file" => "included", "line" => 1 } ],
      "html" => "Included"
    } ]

  end

end
