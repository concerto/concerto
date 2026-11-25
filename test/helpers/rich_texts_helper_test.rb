require "test_helper"

class RichTextsHelperTest < ActionView::TestCase
  test "returns no warnings for plaintext rich text even with script tags" do
    rt = RichText.new(text: "<script>alert(1)</script>", render_as: "plaintext")
    assert_empty rich_text_html_warnings(rt)
    refute rich_text_has_active_html?(rt)
  end

  test "returns no warnings for non-RichText content" do
    assert_empty rich_text_html_warnings(Graphic.new)
    refute rich_text_has_active_html?(nil)
  end

  test "returns no warnings for safe HTML markup" do
    rt = RichText.new(
      text: '<h1>Welcome</h1><p>Hello &amp; welcome!<br/>Visit <a href="https://example.com">our site</a>.</p>',
      render_as: "html"
    )
    assert_empty rich_text_html_warnings(rt)
    refute rich_text_has_active_html?(rt)
  end

  test "detects script elements" do
    rt = RichText.new(text: "<p>Hi</p><script>alert(1)</script>", render_as: "html")
    warnings = rich_text_html_warnings(rt)
    assert_includes warnings, "<script> element"
    assert rich_text_has_active_html?(rt)
  end

  test "detects iframe, object, embed, svg, and style elements" do
    %w[iframe object embed svg style meta link base].each do |tag|
      rt = RichText.new(text: "<#{tag}></#{tag}>", render_as: "html")
      assert_includes rich_text_html_warnings(rt), "<#{tag}> element", "Expected <#{tag}> to be detected"
    end
  end

  test "detects inline event handler attributes case-insensitively" do
    rt = RichText.new(text: '<img src="https://example.com/x.png" ONERROR="alert(1)" onclick="foo()">', render_as: "html")
    warnings = rich_text_html_warnings(rt)
    assert warnings.any? { |w| w.include?("inline event handler") && w.include?("onerror") && w.include?("onclick") }
  end

  test "detects javascript, vbscript, and data URIs including whitespace-obfuscated variants" do
    [
      '<a href="javascript:alert(1)">click</a>',
      '<a href="  java&#x09;script:alert(1)">click</a>',
      '<a href="vbscript:msgbox(1)">click</a>',
      '<a href="data:text/html,<script>alert(1)</script>">click</a>'
    ].each do |html|
      rt = RichText.new(text: html, render_as: "html")
      assert_includes rich_text_html_warnings(rt), "script/data URI", "Expected #{html} to be detected"
    end
  end

  test "detects srcdoc attribute" do
    rt = RichText.new(text: '<iframe srcdoc="<script>alert(1)</script>"></iframe>', render_as: "html")
    warnings = rich_text_html_warnings(rt)
    assert_includes warnings, "<iframe> element"
    assert_includes warnings, "srcdoc attribute"
  end

  test "detects dangerous style attribute expressions" do
    rt = RichText.new(text: '<div style="width: expression(alert(1))">Hi</div>', render_as: "html")
    assert_includes rich_text_html_warnings(rt), "script/data URI"
  end

  test "detects other HTML tags stripped by the preview sanitizer" do
    rt = RichText.new(text: '<form action="https://example.com"><input name="x"></form>', render_as: "html")
    warnings = rich_text_html_warnings(rt)
    assert warnings.any? { |w| w.include?("HTML stripped from preview") && w.include?("<form>") }
  end
end
