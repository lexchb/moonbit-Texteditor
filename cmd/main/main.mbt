///|
/// CLI demo for moonbit-texteditor Markdown to HTML converter.
fn main {
  let markdown = "# Hello MoonBit\n\nThis is a **paragraph** with `inline code`.\n\n## Section 2\n\n- Item 1\n- Item 2\n\n> A block quote\n\n    indented code block\n\n---"

  println("=== Input Markdown ===")
  println(markdown)
  println("")
  println("=== Output HTML ===")
  let html = @md.render_to_string(markdown)
  println(html)
}
