///|
/// CLI demo for moonbit-texteditor Markdown to HTML converter.
fn main {
  println(
    "╔══════════════════════════════════════════════════════════════╗",
  )
  println("║     MoonBit Markdown to HTML Converter - Demo              ║")
  println(
    "╚══════════════════════════════════════════════════════════════╝",
  )

  // Test 1: Basic CommonMark
  demo(
    "1. Headings & Paragraphs", "# Heading 1\n\n## Heading 2\n\n### Heading 3\n\nThis is a paragraph with **bold** and *italic* text.\n\nAnother paragraph with `inline code`.",
  )

  // Test 2: Lists
  demo(
    "2. Lists", "- Bullet item 1\n- Bullet item 2\n- Bullet item 3\n\n1. Ordered item 1\n2. Ordered item 2",
  )

  // Test 3: Block Quote
  demo(
    "3. Block Quotes", "> This is a block quote\n> with multiple lines\n>\n> > And a nested quote",
  )

  // Test 4: Code Blocks
  demo(
    "4. Code Blocks", "```rust\nfn main() {\n    println!(\"Hello, World!\");\n}\n```\n\n    indented code block",
  )

  // Test 5: Links & Images
  demo(
    "5. Links & Images", "[Click here](https://example.com \"Example\") to visit.\n\n![MoonBit Logo](https://www.moonbitlang.com/favicon.ico \"MoonBit\")",
  )

  // Test 6: Thematic Break
  demo(
    "6. Thematic Break", "Before the line\n\n---\n\nAfter the line\n\n***\n\n___",
  )

  // Test 7: GFM Table (must use render_to_string_with_opts)
  let table_md = "| Feature | Status | Priority |\n|---------|--------|----------|\n| Tables  | ✅ Done | High     |\n| Task Lists | ✅ Done | High |\n| Strikethrough | ✅ Done | Medium |"
  let table_opts = @md.create_markdown_options(
    true, false, false, false, false, false,
  )
  let table_html = @md.render_to_string_with_opts(table_md, table_opts)
  print_demo("7. GFM Tables", table_md, table_html)

  // Test 8: Task List (with options)
  let task_md = "- [x] Completed task\n- [ ] Pending task\n- [ ] Another todo\n- Normal list item"
  let task_opts = @md.create_markdown_options(
    false, true, false, false, false, false,
  )
  let task_html = @md.render_to_string_with_opts(task_md, task_opts)
  print_demo("8. Task Lists", task_md, task_html)

  // Test 9: Strikethrough + Autolink (with options)
  let gfm_md = "This is ~~strikethrough~~ text.\n\nVisit https://moonbitlang.com for more info."
  let gfm_opts = @md.create_markdown_options(
    false, false, true, true, false, false,
  )
  let gfm_html = @md.render_to_string_with_opts(gfm_md, gfm_opts)
  print_demo("9. Strikethrough & Autolink", gfm_md, gfm_html)

  // Test 10: Syntax Highlighting (with options)
  let code_md = "```rust\nfn fibonacci(n: u32) -> u32 {\n    match n {\n        0 => 0,\n        1 => 1,\n        _ => fibonacci(n - 1) + fibonacci(n - 2),\n    }\n}\n```"
  let code_opts = @md.create_markdown_options(
    false, false, false, false, true, false,
  )
  let code_html = @md.render_to_string_with_opts(code_md, code_opts)
  print_demo("10. Syntax Highlighting", code_md, code_html)

  // Test 11: Mixed Content
  let mixed_md = "# Project Overview\n\nThis project is a **Markdown to HTML** converter written in MoonBit.\n\n## Features\n\n- [x] CommonMark core syntax\n- [x] GFM tables, task lists, strikethrough\n- [x] Auto-links\n- [ ] Syntax highlighting (optional)\n\n> **Note:** This library is still in active development.\n\n---\n\nPowered by [MoonBit](https://www.moonbitlang.com)"
  let mixed_opts = @md.create_markdown_options(
    true, true, true, true, false, false,
  )
  let mixed_html = @md.render_to_string_with_opts(mixed_md, mixed_opts)
  print_demo("11. Mixed Content (All Features)", mixed_md, mixed_html)

  // Test 12: Frontmatter metadata
  let fm_md = "---\ntitle: My Document\nauthor: MoonBit\nversion: 1.0.0\n---\n\n# Document Title\n\nThis is the document body."
  let (metadata, remaining) = @md.parse_frontmatter(fm_md)
  let fm_html = @md.render_to_string(remaining)

  println("")
  println(
    "╔══════════════════════════════════════════════════════════════╗",
  )
  println("║     12. Frontmatter Metadata                               ║")
  println(
    "╚══════════════════════════════════════════════════════════════╝",
  )
  println("Metadata extracted:")
  for pair in metadata {
    let (key, value) = pair
    println("  " + key + ": " + value)
  }
  println("")
  println("Rendered body HTML:")
  println(fm_html)

  // Test 13: TOC generation
  let toc_md = "# Title\n\nIntro text\n\n## Section 1\n\nContent\n\n### Subsection 1.1\n\nMore content\n\n## Section 2\n\nFinal content"
  let toc_blocks = @md.parse(toc_md)
  let toc = @md.generate_toc(toc_blocks)

  println("")
  println(
    "╔══════════════════════════════════════════════════════════════╗",
  )
  println("║     13. Table of Contents                                  ║")
  println(
    "╚══════════════════════════════════════════════════════════════╝",
  )
  for entry in toc {
    let (level, text) = entry
    let indent = level - 1
    let mut prefix = ""
    let mut ci = 0
    while ci < indent {
      prefix = prefix + "  "
      ci = ci + 1
    }
    println(prefix + "H" + level.to_string() + ": " + text)
  }

  println("")
  println(
    "╔══════════════════════════════════════════════════════════════╗",
  )
  println("║           All demos completed!                             ║")
  println(
    "╚══════════════════════════════════════════════════════════════╝",
  )
  println("Run with: moon run")
}

///|
/// Print a demo section with markdown input and HTML output.
fn demo(title : String, markdown : String) -> Unit {
  print_demo(title, markdown, @md.render_to_string(markdown))
}

///|
/// Print a formatted demo section.
fn print_demo(title : String, markdown : String, html : String) -> Unit {
  println("")
  println(
    "╔══════════════════════════════════════════════════════════════╗",
  )
  println("║     " + title)
  println(
    "╚══════════════════════════════════════════════════════════════╝",
  )
  println("Markdown Input:")
  println(markdown)
  println("")
  println("HTML Output:")
  println(html)
}
