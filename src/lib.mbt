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
