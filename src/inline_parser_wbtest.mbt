///|
/// Phase 2: Whitebox tests for the full inline parser

///|
test "escape: backslash star" {
  let input = "Hello \\*World*"
  println(
    "──────────────────────────────────",
  )
  println("Test: escape backslash star")
  println("Input: " + input)
  let blocks = parse(input)
  let html = render_to_string(input)
  println("HTML : " + html)
  match blocks[0] {
    Paragraph(inlines) => {
      assert_eq(inlines.length(), 4)
      match inlines[0] {
        Text(t) => assert_eq(t, "Hello ")
        _ => fail("expected Text")
      }
      match inlines[1] {
        Text(t) => assert_eq(t, "*")
        _ => fail("expected Text for escaped *")
      }
      match inlines[2] {
        Text(t) => assert_eq(t, "World")
        _ => fail("expected Text")
      }
      match inlines[3] {
        Text(t) => assert_eq(t, "*")
        _ => fail("expected Text for trailing unmatched delimiter")
      }
      println("Result: Text(\"Hello \") + Text(\"*\") + Text(\"World*\") ✓")
    }
    _ => fail("expected Paragraph")
  }
}

///|
test "emphasis: single star" {
  let input = "Hello *italic* world"
  println(
    "──────────────────────────────────",
  )
  println("Test: emphasis single star")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<em>italic</em>"))
  println("Result: <em>italic</em> ✓")
}

///|
test "emphasis: single underscore" {
  let input = "Hello _italic_ world"
  println(
    "──────────────────────────────────",
  )
  println("Test: emphasis single underscore")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<em>italic</em>"))
  println("Result: <em>italic</em> ✓")
}

///|
test "strong: double star" {
  let input = "Hello **bold** world"
  println(
    "──────────────────────────────────",
  )
  println("Test: strong double star")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<strong>bold</strong>"))
  println("Result: <strong>bold</strong> ✓")
}

///|
test "strong: double underscore" {
  let input = "Hello __bold__ world"
  println(
    "──────────────────────────────────",
  )
  println("Test: strong double underscore")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<strong>bold</strong>"))
  println("Result: <strong>bold</strong> ✓")
}

///|
test "emphasis nested in strong" {
  let input = "**bold *italic* bold**"
  println(
    "──────────────────────────────────",
  )
  println("Test: emphasis nested in strong")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<strong>") && html.contains("<em>"))
  println("Result: <strong>bold <em>italic</em> bold</strong> ✓")
}

///|
test "link: simple" {
  let input = "[click here](https://example.com)"
  println(
    "──────────────────────────────────",
  )
  println("Test: link simple")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<a href=\"https://example.com\">"))
  assert_true(html.contains("click here"))
  println("Result: <a href=\"...\">click here</a> ✓")
}

///|
test "link: with title" {
  let input = "[link](https://example.com \"Example Site\")"
  println(
    "──────────────────────────────────",
  )
  println("Test: link with title")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("title=\"Example Site\""))
  assert_true(html.contains("<a href="))
  println("Result: <a href=\"...\" title=\"Example Site\"> ✓")
}

///|
test "image: simple" {
  let input = "![alt text](image.png)"
  println(
    "──────────────────────────────────",
  )
  println("Test: image simple")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<img src=\"image.png\" alt=\"alt text\""))
  println("Result: <img src=\"image.png\" alt=\"alt text\" /> ✓")
}

///|
test "html inline: simple tag" {
  let input = "Hello <span>world</span>"
  println(
    "──────────────────────────────────",
  )
  println("Test: html inline simple tag")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<span>") && html.contains("</span>"))
  println("Result: Hello <span>world</span> ✓")
}

///|
test "html inline: br tag" {
  let input = "Line1<br/>Line2"
  println(
    "──────────────────────────────────",
  )
  println("Test: html inline br tag")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<br/>"))
  println("Result: <br/> ✓")
}

///|
test "combined: emphasis and link" {
  let input = "**bold** and [link](url) with `code`"
  println(
    "──────────────────────────────────",
  )
  println("Test: combined emphasis and link")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<strong>bold</strong>"))
  assert_true(html.contains("<a href=\"url\">"))
  assert_true(html.contains("<code>code</code>"))
  println("Result: <strong> + <a> + <code> ✓")
}

///|
test "unmatched delimiter rendered as text" {
  let input = "Hello * world"
  println(
    "──────────────────────────────────",
  )
  println("Test: unmatched delimiter rendered as text")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("*"))
  println("Result: * rendered as text ✓")
}

///|
test "emphasis: mixed star and underscore" {
  let input = "*italic* and _italic_ and **bold** and __bold__"
  println(
    "──────────────────────────────────",
  )
  println("Test: mixed emphasis and strong")
  println("Input: " + input)
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<em>italic</em>"))
  assert_true(html.contains("<strong>bold</strong>"))
  println("Result: mixed emphasis ✓")
}
