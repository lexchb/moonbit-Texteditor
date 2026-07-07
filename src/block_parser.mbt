///|
/// Parse classified lines into a list of Block nodes.
pub fn parse_blocks(lines : Array[Line]) -> Array[Block] {
  let blocks : Array[Block] = []
  let mut i = 0
  let n = lines.length()

  while i < n {
    let line = lines[i]

    match line.typ {
      Heading(level) => {
        let inlines = parse_inlines_simple(line.content)
        blocks.push(Heading(level, inlines))
        i = i + 1
      }
      ThematicBreak => {
        blocks.push(ThematicBreak)
        i = i + 1
      }
      IndentedCode => {
        // Collect consecutive indented code lines (including blank lines within)
        let code_lines : Array[String] = []
        code_lines.push(line.content)
        i = i + 1
        while i < n {
          let next = lines[i]
          match next.typ {
            IndentedCode => {
              code_lines.push(next.content)
              i = i + 1
            }
            Empty => {
              code_lines.push("")
              i = i + 1
            }
            _ => break
          }
        }
        let code_text = code_lines.join("\n")
        blocks.push(IndentedCodeBlock(code_text))
      }
      FenceStart(lang) => {
        // Open a fenced code block
        let fence_char = if line.raw.length() > 0 { line.raw[0] } else { 96 }
        let code_lines : Array[String] = []
        i = i + 1
        while i < n {
          let next = lines[i]
          // Check for closing fence (FenceEnd or FenceStart with same fence char)
          let is_close = match next.typ {
            FenceEnd => true
            FenceStart(_) => true
            _ => false
          }
          if is_close && next.raw.length() > 0 && next.raw[0] == fence_char {
            i = i + 1
            break
          }
          // Include raw line content as code
          code_lines.push(next.raw)
          i = i + 1
        }
        let code_text = code_lines.join("\n")
        blocks.push(FencedCodeBlock(lang, code_text))
      }
      FenceEnd => {
        // Bare fence with no info string when not already inside a fenced block
        // Treat as FenceStart(None) — open a new fenced code block
        let fence_char = if line.raw.length() > 0 { line.raw[0] } else { 96 }
        let code_lines : Array[String] = []
        i = i + 1
        while i < n {
          let next = lines[i]
          let is_close = match next.typ {
            FenceEnd => true
            FenceStart(_) => true
            _ => false
          }
          if is_close && next.raw.length() > 0 && next.raw[0] == fence_char {
            i = i + 1
            break
          }
          code_lines.push(next.raw)
          i = i + 1
        }
        let code_text = code_lines.join("\n")
        blocks.push(FencedCodeBlock(None, code_text))
      }
      BlockQuote => {
        // Collect consecutive block quote lines
        let quote_lines : Array[String] = []
        quote_lines.push(line.content)
        i = i + 1
        while i < n {
          let next = lines[i]
          match next.typ {
            BlockQuote => {
              quote_lines.push(next.content)
              i = i + 1
            }
            Empty => {
              quote_lines.push("")
              i = i + 1
            }
            _ => break
          }
        }
        let quote_text = quote_lines.join("\n")
        // Recursively parse the quote content
        let inner_blocks = parse_blocks(tokenize(quote_text))
        blocks.push(BlockQuote(inner_blocks))
      }
      BulletItem(_marker) => {
        // Collect consecutive bullet list items
        let items = []
        let mut tight = true

        while i < n {
          let current = lines[i]
          match current.typ {
            BulletItem(_) => {
              // Single paragraph item
              let inlines = parse_inlines_simple(current.content)
              let children : Array[Block] = [Paragraph(inlines)]
              items.push({ checked: false, children })
              i = i + 1
            }
            Empty => {
              // Blank line between items → loose list
              tight = false
              i = i + 1
              // Skip subsequent blank lines
              while i < n {
                match lines[i].typ {
                  Empty => i = i + 1
                  _ => break
                }
              }
            }
            _ => break
          }
        }
        blocks.push(BulletList(items, tight))
      }
      OrderedItem(_num) => {
        // Collect consecutive ordered list items
        let items = []
        let mut tight = true

        while i < n {
          let current = lines[i]
          match current.typ {
            OrderedItem(_) => {
              let inlines = parse_inlines_simple(current.content)
              let children : Array[Block] = [Paragraph(inlines)]
              items.push({ checked: false, children })
              i = i + 1
            }
            Empty => {
              tight = false
              i = i + 1
              while i < n {
                match lines[i].typ {
                  Empty => i = i + 1
                  _ => break
                }
              }
            }
            _ => break
          }
        }
        blocks.push(OrderedList(items, 1, tight))
      }
      Empty => i = i + 1
      TableRow =>
        // Phase 2: Table support
        i = i + 1
      Paragraph => {
        // Collect consecutive paragraph lines
        let para_lines : Array[String] = []
        para_lines.push(line.content)
        i = i + 1
        while i < n {
          let next = lines[i]
          match next.typ {
            Paragraph => {
              para_lines.push(next.content)
              i = i + 1
            }
            Empty => {
              i = i + 1
              break
            }
            _ => break
          }
        }
        let para_text = para_lines.join(" ")
        let inlines = parse_inlines_simple(para_text)
        blocks.push(Paragraph(inlines))
      }
    }
  }

  blocks
}

///|
/// Very simple inline parser for Phase 1.
/// Parses: Text, Code (backtick).
/// Emphasis, Link, etc will be added in Phase 2.
fn parse_inlines_simple(text : String) -> Array[Inline] {
  let result : Array[Inline] = []
  let mut i = 0
  let n = text.length()

  while i < n {
    // Inline code: `...`
    if text[i] == 96 { // '`'
      let mut j = i + 1
      while j < n && text[j] != 96 {
        j = j + 1
      }
      if j < n {
        // Properly closed inline code
        let code_content = text[i + 1:j].to_owned()
        result.push(Code(code_content))
        i = j + 1
      } else {
        // Unclosed backtick, treat as text
        result.push(Text("`"))
        i = i + 1
      }
    } else {
      // Collect consecutive text characters until a special char is found
      let mut j = i
      while j < n && text[j] != 96 { // '`'
        j = j + 1
      }
      let text_content = text[i:j].to_owned()
      if text_content.length() > 0 {
        result.push(Text(text_content))
      }
      i = j
    }
  }

  result
}
