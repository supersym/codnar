require "codnar"
require "olag/test"
require "test/spec"
require "test_with_configurations"

# Test combinations of the built-in split code configurations.
class TestSplitCodeConfigurations < Test::Unit::TestCase

  include Test::WithConfigurations
  include Test::WithErrors
  include Test::WithTempfile

  SOURCE_CODE = <<-EOF.unindent
    a = b
    b = 1
  EOF

  def test_source_code
    check_split_file(SOURCE_CODE, Codnar::Configuration::CLASSIFY_SOURCE_CODE.call("ruby")) do |path|
      [ {
        "name" => path,
        "locations" => [ { "file" => path, "line" => 1 } ],
        "containers" => [],
        "contained" => [],
        "html" => "<pre class='code'>\n#{SOURCE_CODE}</pre>"
      } ]
    end
  end

  ISLAND_CODE = <<-EOF.unindent
    a = b
    b = 1
    HTML = <<-EOH.unindent # ((( html
      <p>
      HTML
      </p>
    EOH
    # ))) html
  EOF

  ISLAND_HTML = <<-EOF.unindent.chomp
    <pre class='ruby code syntax'>
    a = b
    b = <span class="Constant">1</span>
    <span class="Type">HTML</span> = &lt;&lt;-<span class="Special">EOH</span>.unindent <span class="Comment"># ((( html</span>
    </pre>
    <pre class='html code syntax'>
      <span class="Identifier">&lt;</span><span class="Statement">p</span><span class="Identifier">&gt;</span>
      HTML
      <span class="Identifier">&lt;/</span><span class="Statement">p</span><span class="Identifier">&gt;</span>
    EOH
    </pre>
    <pre class='ruby code syntax'>
    <span class="Comment"># ))) html</span>
    </pre>
  EOF

  def test_island_code
    check_split_file(ISLAND_CODE, Codnar::Configuration::CLASSIFY_SOURCE_CODE.call("ruby"),
                                  Codnar::Configuration::FORMAT_CODE_GVIM_CSS.call("ruby"),
                                  Codnar::Configuration::CLASSIFY_NESTED_CODE.call("ruby", "html"),
                                  Codnar::Configuration::FORMAT_CODE_GVIM_CSS.call("html")) do |path|
      [ {
        "name" => path,
        "locations" => [ { "file" => path, "line" => 1 } ],
        "containers" => [],
        "contained" => [],
        "html" => ISLAND_HTML
      } ]
    end
  end

end
