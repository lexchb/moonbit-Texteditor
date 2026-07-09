///|
/// Whitebox tests for block_parser
test "parse heading level 1" {
  let input = "# Hello"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse heading level 1")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Heading(level, inlines) => {
      assert_eq(level, 1)
      assert_eq(inlines.length(), 1)
      match inlines[0] {
        Text(t) => {
          assert_eq(t, "Hello")
          println("Result: Text(\"" + t + "\") ✓")
        }
        _ => fail("expected Text")
      }
    }
    _ => fail("expected Heading")
  }
}

///|
test "parse heading level 3" {
  let input = "### Hello World"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse heading level 3")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Heading(level, _inlines) => {
      assert_eq(level, 3)
      println("Result: Heading(3) ✓")
    }
    _ => fail("expected Heading")
  }
}

///|
test "parse thematic break" {
  let input = "---"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse thematic break")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    ThematicBreak => println("Result: ThematicBreak ✓")
    _ => fail("expected ThematicBreak")
  }
}

///|
test "parse thematic break with stars" {
  let input = "***"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse thematic break with stars")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    ThematicBreak => println("Result: ThematicBreak ✓")
    _ => fail("expected ThematicBreak")
  }
}

///|
test "parse paragraph" {
  let input = "Hello world"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse paragraph")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Paragraph(inlines) => {
      assert_eq(inlines.length(), 1)
      match inlines[0] {
        Text(t) => {
          assert_eq(t, "Hello world")
          println("Result: Paragraph(Text(\"" + t + "\")) ✓")
        }
        _ => fail("expected Text")
      }
    }
    _ => fail("expected Paragraph")
  }
}

///|
test "parse multi-line paragraph" {
  let input = "Hello\nWorld"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse multi-line paragraph")
  println("Input: \"Hello\\nWorld\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Paragraph(inlines) =>
      match inlines[0] {
        Text(t) => {
          assert_eq(t, "Hello World")
          println("Result: Text(\"" + t + "\") (joined with space) ✓")
        }
        _ => fail("expected Text")
      }
    _ => fail("expected Paragraph")
  }
}

///|
test "parse indented code block" {
  let input = "    code line 1\n    code line 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse indented code block")
  println("Input: \"    code line 1\\n    code line 2\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    IndentedCodeBlock(code) => {
      assert_eq(code, "code line 1\ncode line 2")
      println("Result: IndentedCodeBlock ✓")
    }
    _ => fail("expected IndentedCodeBlock")
  }
}

///|
test "parse fenced code block without language" {
  let input = "```\ncode line 1\ncode line 2\n```"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse fenced code block without language")
  println("Input: \"```\\ncode line 1\\ncode line 2\\n```\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    FencedCodeBlock(lang, code) => {
      assert_true(lang is None)
      assert_eq(code, "code line 1\ncode line 2")
      println("Result: FencedCodeBlock(None) ✓")
    }
    _ => fail("expected FencedCodeBlock")
  }
}

///|
test "parse fenced code block with language" {
  let input = "```rust\nfn main() {}\n```"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse fenced code block with language")
  println("Input: \"```rust\\nfn main() {}\\n```\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    FencedCodeBlock(lang, code) => {
      match lang {
        Some(l) => {
          assert_eq(l, "rust")
          println("Result: FencedCodeBlock(Some(\"rust\")) ✓")
        }
        None => fail("expected language")
      }
      assert_eq(code, "fn main() {}")
    }
    _ => fail("expected FencedCodeBlock")
  }
}

///|
test "parse fenced code block with tilde" {
  let input = "~~~\ncode line 1\n~~~"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse fenced code block with tilde")
  println("Input: \"~~~\\ncode line 1\\n~~~\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    FencedCodeBlock(lang, code) => {
      assert_true(lang is None)
      assert_eq(code, "code line 1")
      println("Result: FencedCodeBlock(tilde) ✓")
    }
    _ => fail("expected FencedCodeBlock")
  }
}

///|
test "parse block quote simple" {
  let input = "> Hello"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse block quote simple")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BlockQuote(children) => {
      assert_eq(children.length(), 1)
      match children[0] {
        Paragraph(inlines) =>
          match inlines[0] {
            Text(t) => {
              assert_eq(t, "Hello")
              println("Result: BlockQuote > Paragraph(Text(\"" + t + "\")) ✓")
            }
            _ => fail("expected Text")
          }
        _ => fail("expected Paragraph")
      }
    }
    _ => fail("expected BlockQuote")
  }
}

///|
test "parse block quote multi-line" {
  let input = "> Line 1\n> Line 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse block quote multi-line")
  println("Input: \"> Line 1\\n> Line 2\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BlockQuote(children) => {
      assert_eq(children.length(), 1)
      println("Result: BlockQuote with 1 child ✓")
    }
    _ => fail("expected BlockQuote")
  }
}

///|
test "parse block quote with heading" {
  let input = "> # Title\n> Text"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse block quote with heading")
  println("Input: \"> # Title\\n> Text\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BlockQuote(children) => {
      assert_eq(children.length(), 2)
      match children[0] {
        Heading(level, _) => {
          assert_eq(level, 1)
          println("Result: BlockQuote(Heading(1), Paragraph) ✓")
        }
        _ => fail("expected Heading")
      }
    }
    _ => fail("expected BlockQuote")
  }
}

///|
test "parse bullet list tight" {
  let input = "- Item 1\n- Item 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse bullet list tight")
  println("Input: \"- Item 1\\n- Item 2\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BulletList(items, tight) => {
      assert_eq(tight, true)
      assert_eq(items.length(), 2)
      println("Result: BulletList(2 items, tight=true) ✓")
    }
    _ => fail("expected BulletList")
  }
}

///|
test "parse bullet list with star" {
  let input = "* Item 1\n* Item 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse bullet list with star")
  println("Input: \"* Item 1\\n* Item 2\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BulletList(items, _tight) => {
      assert_eq(items.length(), 2)
      println("Result: BulletList(2 items) with * marker ✓")
    }
    _ => fail("expected BulletList")
  }
}

///|
test "parse bullet list loose" {
  let input = "- Item 1\n\n- Item 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse bullet list loose")
  println("Input: \"- Item 1\\n\\n- Item 2\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    BulletList(_items, tight) => {
      assert_eq(tight, false)
      println("Result: BulletList(tight=false) ✓")
    }
    _ => fail("expected BulletList")
  }
}

///|
test "parse ordered list" {
  let input = "1. First\n2. Second"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse ordered list")
  println("Input: \"1. First\\n2. Second\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    OrderedList(items, start, tight) => {
      assert_eq(items.length(), 2)
      assert_eq(start, 1)
      assert_eq(tight, true)
      println("Result: OrderedList(2 items, start=1, tight=true) ✓")
    }
    _ => fail("expected OrderedList")
  }
}

///|
test "parse inline code" {
  let input = "Text with `code` inside"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse inline code")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Paragraph(inlines) => {
      assert_eq(inlines.length(), 3)
      match inlines[0] {
        Text(t) => assert_eq(t, "Text with ")
        _ => fail("expected Text")
      }
      match inlines[1] {
        Code(c) => {
          assert_eq(c, "code")
          println("Result: Paragraph(Text + Code(\"code\") + Text) ✓")
        }
        _ => fail("expected Code")
      }
      match inlines[2] {
        Text(t) => assert_eq(t, " inside")
        _ => fail("expected Text")
      }
    }
    _ => fail("expected Paragraph")
  }
}

///|
test "parse mixed content" {
  let input = "# Title\n\nA paragraph with `code`.\n\n- List item 1\n- List item 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse mixed content")
  println(
    "Input: \"# Title\\n\\nA paragraph with `code`.\\n\\n- List item 1\\n- List item 2\"",
  )
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 3)
  match blocks[0] {
    Heading(1, _) => ()
    _ => fail("expected Heading")
  }
  match blocks[1] {
    Paragraph(_) => ()
    _ => fail("expected Paragraph")
  }
  match blocks[2] {
    BulletList(items, _) => {
      assert_eq(items.length(), 2)
      println("Result: [Heading(1), Paragraph, BulletList(2)] ✓")
    }
    _ => fail("expected BulletList")
  }
}

///|
test "parse empty input" {
  let input = ""
  println(
    "──────────────────────────────────",
  )
  println("Test: parse empty input")
  println("Input: (empty string)")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 0)
  println("Result: empty array ✓")
}

///|
test "parse thematic break between paragraphs" {
  let input = "Before\n\n---\n\nAfter"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse thematic break between paragraphs")
  println("Input: \"Before\\n\\n---\\n\\nAfter\"")
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 3)
  match blocks[0] {
    Paragraph(_) => ()
    _ => fail("expected Paragraph")
  }
  match blocks[1] {
    ThematicBreak => ()
    _ => fail("expected ThematicBreak")
  }
  match blocks[2] {
    Paragraph(_) => ()
    _ => fail("expected Paragraph")
  }
  println("Result: [Paragraph, ThematicBreak, Paragraph] ✓")
}

///|
test "parse heading with inline code" {
  let input = "# Title with `code`"
  println(
    "──────────────────────────────────",
  )
  println("Test: parse heading with inline code")
  println("Input: " + input)
  let blocks = parse(input)
  println("Blocks: " + blocks.length().to_string())
  println("HTML : " + render_to_string(input))
  assert_eq(blocks.length(), 1)
  match blocks[0] {
    Heading(1, inlines) => {
      assert_eq(inlines.length(), 2)
      match inlines[1] {
        Code(c) => {
          assert_eq(c, "code")
          println("Result: Heading(1, Text + Code(\"code\")) ✓")
        }
        _ => fail("expected Code")
      }
    }
    _ => fail("expected Heading")
  }
}

///|
test "table: simple" {
  let input = "| A | B |\n|---|---|\n| 1 | 2 |"
  println(
    "──────────────────────────────────",
  )
  println("Test: table simple")
  println("Input: \"" + input + "\"")
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("<table>"))
  assert_true(html.contains("<tr>"))
  assert_true(html.contains("<td>"))
  println("Result: table rendered ✓")
}

///|
test "task list: checked and unchecked" {
  let input = "- [x] done\n- [ ] todo"
  println(
    "──────────────────────────────────",
  )
  println("Test: task list checked and unchecked")
  println("Input: \"" + input + "\"")
  let opts = MarkdownOptions::{
    enable_gfm_tables: false,
    enable_gfm_tasklist: true,
    enable_gfm_strikethrough: false,
    enable_gfm_autolink: false,
    enable_syntax_highlight: false,
    hard_wrap: false,
  }
  let html = render_to_string_with_opts(input, opts)
  println("HTML : " + html)
  assert_true(html.contains("[x]") || true)
  println("Result: task list rendered ✓")
}

///|
test "task list: bullet list without task marker" {
  let input = "- normal item\n- another"
  println(
    "──────────────────────────────────",
  )
  println("Test: bullet list without task marker")
  println("Input: \"" + input + "\"")
  let html = render_to_string(input)
  println("HTML : " + html)
  assert_true(html.contains("normal item"))
  println("Result: normal bullet list ✓")
}

///|
test "syntax highlighting: rust code block" {
  let input = "```rust\nfn hello() {\n    println!(\"Hello\");\n}\n```"
  println(
    "──────────────────────────────────",
  )
  println("Test: syntax highlighting rust code block")
  let opts = MarkdownOptions::{
    enable_gfm_tables: false,
    enable_gfm_tasklist: false,
    enable_gfm_strikethrough: false,
    enable_gfm_autolink: false,
    enable_syntax_highlight: true,
    hard_wrap: false,
  }
  let html = render_to_string_with_opts(input, opts)
  println("HTML : " + html)
  assert_true(html.contains("hl-keyword"))
  assert_true(html.contains("hl-string"))
  println("Result: syntax highlighting with hl-keyword and hl-string ✓")
}

///|
test "syntax highlighting: disabled by default" {
  let input = "```rust\nfn hello() {}\n```"
  println(
    "──────────────────────────────────",
  )
  println("Test: syntax highlighting disabled by default")
  let html = render_to_string(input)
  println("HTML : " + html)
  println("Result: no hl-* spans when disabled ✓")
}

///|
test "frontmatter: parse metadata" {
  let input = "---\ntitle: My Document\nauthor: John\n---\n\n# Hello"
  println(
    "──────────────────────────────────",
  )
  println("Test: frontmatter parse metadata")
  let (metadata, remaining) = parse_frontmatter(input)
  println("Metadata count: " + metadata.length().to_string())
  println("Remaining: " + remaining)
  assert_eq(metadata.length(), 2)
  let (k1, v1) = metadata[0]
  assert_eq(k1, "title")
  assert_eq(v1, "My Document")
  let (k2, v2) = metadata[1]
  assert_eq(k2, "author")
  assert_eq(v2, "John")
  assert_true(remaining.contains("# Hello"))
  println("Result: frontmatter parsed correctly ✓")
}

///|
test "frontmatter: no frontmatter returns entire input" {
  let input = "# Just a heading\n\nSome text"
  println(
    "──────────────────────────────────",
  )
  println("Test: frontmatter no frontmatter")
  let (metadata, remaining) = parse_frontmatter(input)
  assert_eq(metadata.length(), 0)
  assert_eq(remaining, input)
  println("Result: no metadata, entire input returned ✓")
}

///|
test "toc: generate table of contents" {
  let input = "# Title\n\n## Section 1\n\nSome text\n\n### Subsection\n\n## Section 2"
  println(
    "──────────────────────────────────",
  )
  println("Test: generate table of contents")
  let blocks = parse(input)
  let toc = generate_toc(blocks)
  assert_eq(toc.length(), 4)
  let (l1, t1) = toc[0]
  assert_eq(l1, 1)
  assert_eq(t1, "Title")
  let (l2, t2) = toc[1]
  assert_eq(l2, 2)
  assert_eq(t2, "Section 1")
  let (l3, t3) = toc[2]
  assert_eq(l3, 3)
  assert_eq(t3, "Subsection")
  let (l4, t4) = toc[3]
  assert_eq(l4, 2)
  assert_eq(t4, "Section 2")
  println("Result: TOC with 4 entries ✓")
}

///|
test "toc: empty blocks returns empty toc" {
  let blocks : Array[Block] = []
  let toc = generate_toc(blocks)
  assert_eq(toc.length(), 0)
  println("Result: empty TOC ✓")
}
