///|
/// Parse a Markdown string into a Block AST.
pub fn parse(input : String) -> Array[Block] {
  let lines = tokenize(input)
  parse_blocks(lines, default_options())
}

///|
/// Parse a Markdown string into a Block AST with custom options.
pub fn parse_with_opts(input : String, opts : MarkdownOptions) -> Array[Block] {
  let lines = tokenize(input)
  parse_blocks(lines, opts)
}

///|
/// Render a Block AST to HTML string.
pub fn render(blocks : Array[Block]) -> String {
  render_html(blocks)
}

///|
/// Convenience function: parse Markdown and render to HTML in one call.
pub fn render_to_string(input : String) -> String {
  let blocks = parse(input)
  render(blocks)
}

///|
/// Convenience function with custom options.
pub fn render_to_string_with_opts(
  input : String,
  opts : MarkdownOptions,
) -> String {
  let blocks = parse_with_opts(input, opts)
  render_html_with_opts(blocks, opts)
}

///|
/// Render with options.
pub fn render_html_with_opts(
  blocks : Array[Block],
  opts : MarkdownOptions,
) -> String {
  let renderer = HtmlRenderer::new_with_opts(opts)
  renderer.render_blocks(blocks)
}

///|
/// Parse frontmatter metadata from a Markdown string.
/// Returns a tuple of (metadata pairs, remaining Markdown content).
/// Frontmatter is enclosed between --- delimiters at the start of input.
/// Each line should be in the format "key: value".
pub fn parse_frontmatter(input : String) -> (Array[(String, String)], String) {
  let lines = tokenize(input)
  let metadata : Array[(String, String)] = []

  // Check if first non-empty line starts with ---
  let mut i = 0
  while i < lines.length() {
    match lines[i].typ {
      Empty => i = i + 1
      _ => break
    }
  }

  if i >= lines.length() || lines[i].raw.trim().to_owned() != "---" {
    return (metadata, input)
  }

  // Collect lines until closing ---
  let mut j = i + 1
  let mut found_close = false
  while j < lines.length() {
    if lines[j].raw.trim().to_owned() == "---" {
      found_close = true
      j = j + 1
      break
    }
    // Parse key: value pairs
    let trimmed = lines[j].raw.trim().to_owned()
    if trimmed.length() > 0 {
      let colon_pos = find_char(trimmed, 58) // ':'
      if colon_pos > 0 {
        let key = trimmed[:colon_pos].trim().to_owned()
        let value = if colon_pos + 1 < trimmed.length() {
          trimmed[colon_pos + 1:].trim().to_owned()
        } else {
          ""
        }
        metadata.push((key, value))
      }
    }
    j = j + 1
  }

  if !found_close {
    return (metadata, input)
  }

  // Reconstruct remaining content from remaining lines
  let remaining_lines : Array[String] = []
  while j < lines.length() {
    remaining_lines.push(lines[j].raw)
    j = j + 1
  }

  let remaining = remaining_lines.join("\n")
  (metadata, remaining)
}

///|
/// Find the first occurrence of a character in a string.
fn find_char(s : String, ch : UInt16) -> Int {
  let mut i = 0
  while i < s.length() {
    if s[i] == ch {
      return i
    }
    i = i + 1
  }
  -1
}

///|
/// Generate a table of contents from a list of Block nodes.
/// Returns an array of (heading_level, heading_text) tuples.
pub fn generate_toc(blocks : Array[Block]) -> Array[(Int, String)] {
  let toc : Array[(Int, String)] = []
  collect_headings(blocks, toc)
  toc
}

///|
/// Recursively collect headings from blocks into the TOC array.
fn collect_headings(blocks : Array[Block], toc : Array[(Int, String)]) -> Unit {
  for block in blocks {
    match block {
      Heading(level, inlines) => {
        let text = inline_text(inlines)
        toc.push((level, text))
      }
      Document(children) => collect_headings(children, toc)
      BlockQuote(children) => collect_headings(children, toc)
      BulletList(items, _) =>
        for item in items {
          collect_headings(item.children, toc)
        }
      OrderedList(items, _, _) =>
        for item in items {
          collect_headings(item.children, toc)
        }
      ListItem(_, children) => collect_headings(children, toc)
      _ => ()
    }
  }
}

///|
/// Extract plain text from inline nodes.
fn inline_text(inlines : Array[Inline]) -> String {
  let buf = StringBuilder()
  for inline in inlines {
    match inline {
      Text(t) => buf.write_string(t)
      Code(c) => buf.write_string(c)
      Emphasis(inner) => buf.write_string(inline_text(inner))
      Strong(inner) => buf.write_string(inline_text(inner))
      Strikethrough(inner) => buf.write_string(inline_text(inner))
      Link(inner, _, _) => buf.write_string(inline_text(inner))
      SoftBreak => buf.write_string(" ")
      LineBreak => buf.write_string(" ")
      _ => ()
    }
  }
  buf.to_string()
}
