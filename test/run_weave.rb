require "codnar"
require "olag/test"
require "test/spec"

# Test running the Weave Codnar Application.
class TestRunWeave < Test::Unit::TestCase

  include Test::WithFakeFS

  def test_print_help
    Codnar::Application.with_argv(%w(-o stdout -h)) { Codnar::Weave.new(true).run }.should == 0
    help = File.read("stdout")
    [ "codnar-weave", "OPTIONS", "DESCRIPTION" ].each { |text| help.should.include?(text) }
  end

  ROOT_CHUNKS = [ {
    "name" => "root",
    "locations" => [ { "file" => "root", "line" => 1 } ],
    "html" => "Root\n<embed src='included' type='x-codnar/include'/>\n"
  } ]

  INCLUDED_CHUNKS = [ {
    "name" => "included",
    "locations" => [ { "file" => "included", "line" => 1 } ],
    "html" => "Included"
  } ]

  def test_run_weave
    write_fake_file("root", ROOT_CHUNKS.to_yaml)
    write_fake_file("included", INCLUDED_CHUNKS.to_yaml)
    Codnar::Application.with_argv(%w(-o stdout root included)) { Codnar::Weave.new(true).run }.should == 0
    File.read("stdout").should == "Root\nIncluded\n"
  end

  def test_run_weave_missing_chunk
    write_fake_file("root", ROOT_CHUNKS.to_yaml)
    Codnar::Application.with_argv(%w(-e stderr -o stdout root)) { Codnar::Weave.new(true).run }.should == 1
    File.read("stderr").should == "#{$0}: Missing chunk: included in file: root\n"
  end

  def test_run_weave_unused_chunk
    write_fake_file("root", ROOT_CHUNKS.to_yaml)
    write_fake_file("included", INCLUDED_CHUNKS.to_yaml)
    Codnar::Application.with_argv(%w(-e stderr -o stdout included root)) { Codnar::Weave.new(true).run }.should == 1
    File.read("stderr").should == "#{$0}: Unused chunk: root in file: root at line: 1\n"
  end

  FILE_CHUNKS = [ {
    "name" => "root",
    "locations" => [ { "file" => "root", "line" => 1 } ],
    "html" => "Root\n<embed src='included.file' type='x-codnar/file'/>\n"
  } ]

  def test_run_weave_missing_file
    write_fake_file("root", FILE_CHUNKS.to_yaml)
    Codnar::Application.with_argv(%w(-e stderr -o stdout root)) { Codnar::Weave.new(true).run }.should == 1
    File.read("stdout").should == "Root\nFILE: included.file EXCEPTION: No such file or directory - included.file\n"
    File.read("stderr").should \
      == "#{$0}: Reading file: included.file exception: No such file or directory - included.file in file: root at line: 1\n"
  end

  def test_run_weave_existing_file
    write_fake_file("root", FILE_CHUNKS.to_yaml)
    write_fake_file("included.file", "included file\n")
    Codnar::Application.with_argv(%w(-e stderr -o stdout root)) { Codnar::Weave.new(true).run }.should == 0
    File.read("stdout").should == "Root\nincluded file\n"
  end

end
