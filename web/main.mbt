///|
/// Web demo module - forces all needed functions to be compiled.
/// Built with: moon build --target js

///|
/// Render Markdown to HTML using default options.
pub fn render_md(input : String) -> String {
  @md.render_to_string(input)
}

///|
/// Render Markdown to HTML with custom options.
pub fn render_md_opts(
  input : String,
  enable_gfm_tables : Bool,
  enable_gfm_tasklist : Bool,
  enable_gfm_strikethrough : Bool,
  enable_gfm_autolink : Bool,
  enable_syntax_highlight : Bool,
  hard_wrap : Bool,
) -> String {
  let opts = @md.create_markdown_options(
    enable_gfm_tables, enable_gfm_tasklist, enable_gfm_strikethrough, enable_gfm_autolink,
    enable_syntax_highlight, hard_wrap,
  )
  @md.render_to_string_with_opts(input, opts)
}

///|
/// Parse frontmatter from Markdown text.
pub fn parse_fm(input : String) -> Array[(String, String)] {
  let (metadata, _) = @md.parse_frontmatter(input)
  metadata
}

///|
/// Generate TOC from Markdown text.
pub fn gen_toc(input : String) -> Array[(Int, String)] {
  let blocks = @md.parse(input)
  @md.generate_toc(blocks)
}

///|
fn main {
  // Use all pub functions to force compilation of their dependencies
  let r1 = render_md("# Hello\n\nWorld")
  let r2 = render_md_opts("~~test~~", false, false, true, false, false, false)
  let r3 = parse_fm("---\na: b\n---\n\n# X")
  let r4 = gen_toc("# A\n\n## B")
  // Print results to prevent dead-code elimination
  println(r1)
  println(r2)
  println(r3.length().to_string())
  println(r4.length().to_string())
  println("MoonBit Markdown Editor module loaded")
}
