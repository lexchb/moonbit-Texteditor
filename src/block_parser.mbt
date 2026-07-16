///|
/// Parse classified lines into a list of Block nodes.
pub fn parse_blocks(
  lines : Array[Line],
  opts : MarkdownOptions,
) -> Array[Block] {
  let blocks : Array[Block] = []
  let mut i = 0
  let n = lines.length()

  while i < n {
    let line = lines[i]

    match line.typ {
      ContainerStart(name) => {
        // Collect lines inside the container until ContainerEnd or EOF
        let inner_lines : Array[Line] = []
        i = i + 1
        while i < n {
          match lines[i].typ {
            ContainerEnd => {
              i = i + 1
              break
            }
            _ => {
              inner_lines.push(lines[i])
              i = i + 1
            }
          }
        }
        let inner_blocks = parse_blocks(inner_lines, opts)
        blocks.push(Container(name, inner_blocks))
      }
      ContainerEnd =>
        // Orphaned container end → skip
        i = i + 1
      FootnoteDefStart(label) => {
        // Collect footnote definition content (paragraph-style, may span lines)
        let def_lines : Array[String] = []
        def_lines.push(line.content)
        i = i + 1
        while i < n {
          match lines[i].typ {
            Paragraph => {
              def_lines.push(lines[i].content)
              i = i + 1
            }
            Empty => {
              i = i + 1
              break
            }
            _ => break
          }
        }
        let def_text = def_lines.join(" ")
        let inner_blocks = parse_blocks(tokenize(def_text), opts)
        blocks.push(FootnoteDef(label, inner_blocks))
      }
      Heading(level) => {
        let inlines = parse_inlines_full(line.content, opts)
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
        let inner_blocks = parse_blocks(tokenize(quote_text), opts)
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
              let is_checked = current.content.length() >= 4 &&
                current.content[0] == 91 && // '['
                (current.content[1] == 120 || current.content[1] == 88) && // 'x' or 'X'
                current.content[2] == 93 && // ']'
                current.content[3] == 32 // ' '
              let task_content = if is_checked {
                current.content[4:].to_owned()
              } else if current.content.length() >= 4 &&
                current.content[0] == 91 && // '['
                current.content[1] == 32 && // ' '
                current.content[2] == 93 && // ']'
                current.content[3] == 32 { // ' '
                current.content[4:].to_owned()
              } else {
                current.content
              }
              let inlines = parse_inlines_full(task_content, opts)
              let children : Array[Block] = [Paragraph(inlines)]
              items.push({ checked: is_checked, children })
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
              let is_checked = current.content.length() >= 4 &&
                current.content[0] == 91 && // '['
                (current.content[1] == 120 || current.content[1] == 88) && // 'x' or 'X'
                current.content[2] == 93 && // ']'
                current.content[3] == 32 // ' '
              let task_content = if is_checked {
                current.content[4:].to_owned()
              } else if current.content.length() >= 4 &&
                current.content[0] == 91 && // '['
                current.content[1] == 32 && // ' '
                current.content[2] == 93 && // ']'
                current.content[3] == 32 { // ' '
                current.content[4:].to_owned()
              } else {
                current.content
              }
              let inlines = parse_inlines_full(task_content, opts)
              let children : Array[Block] = [Paragraph(inlines)]
              items.push({ checked: is_checked, children })
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
      TableRow => {
        // Collect consecutive table rows
        let rows : Array[String] = []
        rows.push(line.raw) // Use raw content to preserve pipes
        i = i + 1
        while i < n {
          match lines[i].typ {
            TableRow => {
              rows.push(lines[i].raw)
              i = i + 1
            }
            Empty => {
              i = i + 1
              break
            }
            _ => break
          }
        }

        // Need at least 2 rows (header + separator)
        if rows.length() >= 2 {
          // Parse table structure
          let header_cells = parse_table_row(rows[0])
          let separator_cells = parse_table_row(rows[1])

          // Check if second row is a separator (contains ---)
          let is_separator = is_separator_row(separator_cells)

          if is_separator {
            // Standard table with header
            let header_row = TableRow::{ cells: header_cells }
            let body_rows : Array[TableRow] = []
            let mut ri = 2
            while ri < rows.length() {
              let cells = parse_table_row(rows[ri])
              body_rows.push(TableRow::{ cells, })
              ri = ri + 1
            }
            blocks.push(Table([header_row] + body_rows))
          } else {
            // Not a proper table, treat all rows as body
            let body_rows : Array[TableRow] = []
            let mut ri = 0
            while ri < rows.length() {
              let cells = parse_table_row(rows[ri])
              body_rows.push(TableRow::{ cells, })
              ri = ri + 1
            }
            blocks.push(Table(body_rows))
          }
        }
      }
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
        let inlines = parse_inlines_full(para_text, opts)
        blocks.push(Paragraph(inlines))
      }
    }
  }

  blocks
}

///|
/// Parse a table row string into cell strings.
fn parse_table_row(row : String) -> Array[String] {
  let cells : Array[String] = []
  let trimmed = row.trim().to_owned()
  let mut start = 0
  // Remove leading |
  if trimmed.length() > 0 && trimmed[0] == 124 {
    start = 1
  }
  // Remove trailing |
  let end = if trimmed.length() > 0 && trimmed[trimmed.length() - 1] == 124 {
    trimmed.length() - 1
  } else {
    trimmed.length()
  }
  let content = trimmed[start:end].to_owned()
  // Split by |
  let mut i = 0
  let mut cell_start = 0
  while i < content.length() {
    if content[i] == 124 { // '|'
      cells.push(content[cell_start:i].trim().to_owned())
      cell_start = i + 1
    }
    i = i + 1
  }
  if cell_start <= content.length() {
    cells.push(content[cell_start:].trim().to_owned())
  }
  cells
}

///|
/// Check if a row of cells is a table separator row (all cells contain only --- and optional :).
fn is_separator_row(cells : Array[String]) -> Bool {
  if cells.length() == 0 {
    return false
  }
  for cell in cells {
    let trimmed = cell.trim().to_owned()
    if trimmed.length() == 0 {
      return false
    }
    let mut i = 0
    // Allow leading :
    if trimmed.length() > 0 && trimmed[0] == 58 {
      i = 1
    }
    // Allow trailing :
    let end = if trimmed.length() > 0 && trimmed[trimmed.length() - 1] == 58 {
      trimmed.length() - 1
    } else {
      trimmed.length()
    }
    while i < end {
      if trimmed[i] != 45 {
        return false
      } // '-'
      i = i + 1
    }
    if i == 0 || (i == 1 && trimmed[0] == 58) {
      return false
    } // need at least one dash
  }
  true
}
