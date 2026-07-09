///|
/// Phase 2: Full Inline Parser
/// Supports: Text, Code, SoftBreak, LineBreak, Escape, Emphasis, Strong,
/// Link, Image, HtmlInline
///
/// Architecture:
///   1. First pass: scan text into IntermediateNode list
///   2. Second pass: resolve emphasis using CommonMark delimiter algorithm

///|
/// Emphasis delimiter data stored in Delim nodes.
struct DelimData {
  char : UInt16
  length : Int
  can_open : Bool
  can_close : Bool
  mut active : Bool
}

///|
/// Intermediate node during inline parsing.
enum InlineNode {
  Final(Inline)
  Delim(DelimData)
}

///|
/// Delimiter info used during emphasis resolution.
struct DelimInfo {
  mut closer_node_idx : Int
  char : UInt16
  mut length : Int
  can_open : Bool
  can_close : Bool
  node_idx : Int
  mut used : Bool
}

///|
/// Parse inline content (uses default options).
pub fn parse_inlines(text : String) -> Array[Inline] {
  parse_inlines_full(text, default_options())
}

///|
/// Parse inline content with full feature support (Phase 2).
pub fn parse_inlines_full(
  text : String,
  opts : MarkdownOptions,
) -> Array[Inline] {
  let nodes = scan_to_nodes(text, opts)
  resolve_emphasis(nodes)
}

///|
/// Check if a character is ASCII punctuation (CommonMark definition).
fn is_ascii_punct(ch : UInt16) -> Bool {
  (ch >= 33 && ch <= 47) ||
  (ch >= 58 && ch <= 64) ||
  (ch >= 91 && ch <= 96) ||
  (ch >= 123 && ch <= 126)
}

///|
/// Check if a character is whitespace.
fn is_ws(ch : UInt16) -> Bool {
  ch == 32 || ch == 9 || ch == 10 || ch == 12 || ch == 13
}

///|
/// Scan text into an intermediate array of InlineNode values.
fn scan_to_nodes(text : String, opts : MarkdownOptions) -> Array[InlineNode] {
  let nodes : Array[InlineNode] = []
  let n = text.length()
  let mut i = 0

  while i < n {
    let ch = text[i]

    // 1. Escape: \X (X = any ASCII punctuation or backslash)
    if ch == 92 { // '\'
      if i + 1 < n {
        let next = text[i + 1]
        if is_ascii_punct(next) || next == 92 {
          nodes.push(Final(Text(text[i + 1:i + 2].to_owned())))
          i = i + 2
          continue
        }
      }
    }

    // 2. Inline code: `...`
    if ch == 96 { // '`'
      let mut j = i + 1
      while j < n && text[j] != 96 {
        j = j + 1
      }
      if j < n {
        nodes.push(Final(Code(text[i + 1:j].to_owned())))
        i = j + 1
        continue
      }
    }

    // 3. Hard break: backslash + newline
    if ch == 92 && i + 1 < n && text[i + 1] == 10 { // '\\' + '\n'
      nodes.push(Final(LineBreak))
      i = i + 2
      continue
    }

    // 4. Hard break: two spaces + newline
    if ch == 32 &&
      i + 1 < n &&
      text[i + 1] == 32 &&
      i + 2 < n &&
      text[i + 2] == 10 {
      nodes.push(Final(LineBreak))
      i = i + 3
      continue
    }

    // 5. Soft break: newline
    if ch == 10 { // '\n'
      nodes.push(Final(SoftBreak))
      i = i + 1
      continue
    }

    // 6. HTML inline: <...>
    if ch == 60 { // '<'
      let result = try_html(text, i)
      match result {
        Some((html_str, next)) => {
          nodes.push(Final(HtmlInline(html_str)))
          i = next
          continue
        }
        None => ()
      }
    }

    // 3.5. Strikethrough: ~~text~~ (GFM extension)
    if opts.enable_gfm_strikethrough &&
      ch == 126 &&
      i + 1 < n &&
      text[i + 1] == 126 {
      // Find closing ~~
      let mut j = i + 2
      while j < n {
        if j + 1 < n && text[j] == 126 && text[j + 1] == 126 {
          break
        }
        if text[j] == 10 {
          break
        } // don't cross lines
        j = j + 1
      }
      if j < n && j + 1 < n && text[j] == 126 && text[j + 1] == 126 {
        // Parse inner content recursively
        let inner_text = text[i + 2:j].to_owned()
        let inner_nodes = scan_to_nodes(inner_text, opts)
        let inner_result = resolve_emphasis(inner_nodes)
        nodes.push(Final(Strikethrough(inner_result)))
        i = j + 2
        continue
      }
    }

    // 7. Emphasis delimiter: * or _
    if ch == 42 || ch == 95 { // '*' '_'
      let run_len = count_run(text, i)
      // Determine flanking
      let before = if i > 0 { text[i - 1] } else { 0 }
      let after = if i + run_len < n { text[i + run_len] } else { 0 }

      let left_flanking = after != 0 && !is_ws(after)
      let right_flanking = before != 0 && !is_ws(before)

      let open = left_flanking && (!right_flanking || is_ascii_punct(before))
      let close = right_flanking && (!left_flanking || is_ascii_punct(after))

      // Runs > 2: split into text + 2 delimiter
      if run_len > 2 {
        let text_count = run_len - 2
        nodes.push(Final(Text(text[i:i + text_count].to_owned())))
        let del = DelimData::{
          char: ch,
          length: 2,
          can_open: open,
          can_close: close,
          active: true,
        }
        nodes.push(Delim(del))
        i = i + run_len
        continue
      }

      let del = DelimData::{
        char: ch,
        length: run_len,
        can_open: open,
        can_close: close,
        active: true,
      }
      nodes.push(Delim(del))
      i = i + run_len
      continue
    }

    // 8. Image: ![alt](src)
    if ch == 33 && i + 1 < n && text[i + 1] == 91 { // '!' + '['
      let result = try_link(text, i, true)
      match result {
        Some((inline, next)) => {
          nodes.push(Final(inline))
          i = next
          continue
        }
        None => ()
      }
    }

    // 9. Link: [text](url)
    if ch == 91 { // '['
      let result = try_link(text, i, false)
      match result {
        Some((inline, next)) => {
          nodes.push(Final(inline))
          i = next
          continue
        }
        None => ()
      }
    }

    // 10. Text: collect until next special char
    let mut j = i
    while j < n {
      let c = text[j]
      if c == 92 ||
        c == 96 ||
        c == 60 ||
        c == 42 ||
        c == 95 ||
        c == 33 ||
        c == 91 ||
        c == 10 ||
        c == 126 {
        break
      }
      j = j + 1
    }
    if j > i {
      let raw_text = text[i:j].to_owned()
      // Check for autolinks in text (GFM extension)
      let processed = if opts.enable_gfm_autolink {
        process_autolinks(raw_text)
      } else {
        [Text(raw_text)]
      }
      for node in processed {
        nodes.push(Final(node))
      }
      i = j
    } else {
      // Single char that fell through
      nodes.push(Final(Text(text[i:i + 1].to_owned())))
      i = i + 1
    }
  }

  nodes
}

///|
/// Try to process autolinks in a text string.
/// Returns a list of Inline nodes, splitting at autolink boundaries.
fn process_autolinks(text : String) -> Array[Inline] {
  let result : Array[Inline] = []
  let n = text.length()
  let mut pos = 0
  while pos < n {
    // Search for http:// or https:// starting at any position
    let mut url_start = -1
    let mut is_https = false
    let mut search = pos
    while search < n {
      if search + 8 <= n && text[search:search + 8].to_owned() == "https://" {
        url_start = search
        is_https = true
        break
      } else if search + 7 <= n &&
        text[search:search + 7].to_owned() == "http://" {
        url_start = search
        is_https = false
        break
      }
      search = search + 1
    }

    if url_start < 0 {
      // No URL found, add remaining as text
      if pos < n {
        result.push(Text(text[pos:n].to_owned()))
      }
      break
    }

    // Add text before URL
    if url_start > pos {
      result.push(Text(text[pos:url_start].to_owned()))
    }

    // Scan URL end
    let url_scan_start = if is_https { url_start + 8 } else { url_start + 7 }
    let mut j = url_scan_start
    while j < n {
      let c = text[j]
      if is_ws(c) || c == 93 || c == 41 || c == 34 || c == 39 {
        break
      }
      j = j + 1
    }

    let url = text[url_start:j].to_owned()
    result.push(AutoLink(url, false))
    pos = j
  }
  result
}

///|
/// Count consecutive occurrences of the same character starting at pos.
fn count_run(text : String, pos : Int) -> Int {
  let ch = text[pos]
  let mut count = 0
  let mut i = pos
  while i < text.length() && text[i] == ch {
    count = count + 1
    i = i + 1
  }
  count
}

///|
/// Try to parse an HTML inline tag <...> at position pos.
fn try_html(text : String, pos : Int) -> (String, Int)? {
  let n = text.length()
  if pos >= n || text[pos] != 60 {
    return None
  }

  // Must be followed by letter, '/', or '?'
  if pos + 1 >= n {
    return None
  }
  let second = text[pos + 1]
  if second != 47 && !is_ascii_letter(second) && second != 63 {
    return None
  }

  // Scan to closing '>'
  let mut j = pos + 1
  while j < n && text[j] != 62 { // '>'
    if text[j] == 10 || text[j] == 13 {
      return None
    }
    j = j + 1
  }
  if j >= n {
    return None
  }

  Some((text[pos:j + 1].to_owned(), j + 1))
}

///|
/// Check if a char is an ASCII letter.
fn is_ascii_letter(ch : UInt16) -> Bool {
  (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)
}

///|
/// Try to parse a link [text](url) or image ![alt](src).
fn try_link(text : String, pos : Int, is_image : Bool) -> (Inline, Int)? {
  let n = text.length()
  // For images, pos points to '!'
  let start = if is_image { pos + 1 } else { pos }

  // Must have '[' at start
  if start >= n || text[start] != 91 {
    return None
  }

  // Find matching ']' with balanced bracket counting
  let mut depth = 1
  let mut j = start + 1
  while j < n && depth > 0 {
    let c = text[j]
    if c == 96 { // '`'
      j = j + 1
      while j < n && text[j] != 96 {
        j = j + 1
      }
      if j >= n {
        break
      }
      j = j + 1
      continue
    }
    if c == 91 {
      depth = depth + 1
    }
    if c == 93 {
      depth = depth - 1
    }
    if depth > 0 {
      j = j + 1
    }
  }
  if depth != 0 || j >= n {
    return None
  }

  let bracket_end = j
  let text_content = text[start + 1:bracket_end].to_owned()

  // Look for '(' after ']'
  if bracket_end + 1 >= n || text[bracket_end + 1] != 40 {
    return None
  }

  // Parse content inside (...): URL + optional title
  let paren_open = bracket_end + 1
  let mut k = paren_open + 1
  let mut depth_p = 1
  let mut url_str : String = ""
  let mut title_str : String? = None
  let mut in_title = false
  let mut title_quote : UInt16 = 0
  let mut title_start = -1

  while k < n && depth_p > 0 {
    let c = text[k]
    if c == 41 { // ')'
      depth_p = depth_p - 1
      if depth_p == 0 && in_title {
        title_str = Some(text[title_start:k].to_owned())
        break
      }
    } else if in_title {
      if c == title_quote {
        in_title = false
        title_str = Some(text[title_start:k].to_owned())
      }
    } else if (c == 34 || c == 39) && k > paren_open + 1 { // '"' or '\''
      in_title = true
      title_quote = c
      title_start = k + 1
    } else if c == 40 { // '('
      depth_p = depth_p + 1
    }
    k = k + 1
  }
  if depth_p != 0 {
    return None
  }

  let paren_close = k

  // Extract URL
  url_str = if title_start >= 0 {
    text[paren_open + 1:title_start - 1].trim().to_owned()
  } else {
    text[paren_open + 1:paren_close - 1].trim().to_owned()
  }

  // Parse inline content for link text (recursive)
  let text_nodes = parse_inlines_full(text_content, default_options())

  let result = if is_image {
    Image(text_content, url_str, title_str)
  } else {
    Link(text_nodes, url_str, title_str)
  }

  Some((result, paren_close + 1))
}

///|
/// Resolve emphasis delimiters using the CommonMark algorithm.
/// Takes InlineNode[] and produces Inline[].
fn resolve_emphasis(nodes : Array[InlineNode]) -> Array[Inline] {
  // Step 1: Collect delimiter info
  let delims : Array[DelimInfo] = []
  let mut node_idx = 0
  while node_idx < nodes.length() {
    match nodes[node_idx] {
      Delim(d) =>
        delims.push({
          closer_node_idx: -1,
          char: d.char,
          length: d.length,
          can_open: d.can_open,
          can_close: d.can_close,
          node_idx,
          used: false,
        })
      _ => ()
    }
    node_idx = node_idx + 1
  }

  // Step 2: CommonMark delimiter matching
  let mut stack : Array[Int] = []

  let mut di = 0
  while di < delims.length() {
    let info = delims[di]

    // If this delimiter can close, try to find a matching opener
    if info.can_close {
      let mut si = stack.length() - 1
      while si >= 0 {
        let oi = stack[si]
        let opener = delims[oi]
        if opener.char == info.char && opener.can_open {
          // Found a match!
          let olen = opener.length
          let clen = info.length

          if olen == 1 || clen == 1 {
            // Single delimiter match → Emphasis
            delims[oi].closer_node_idx = info.node_idx
            delims[di].closer_node_idx = oi
            delims[oi].used = true
            delims[di].used = true

            let new_stack : Array[Int] = []
            let mut s = 0
            while s < stack.length() {
              if stack[s] != oi {
                new_stack.push(stack[s])
              }
              s = s + 1
            }
            stack = new_stack
            break
          } else if olen == 2 && clen == 2 {
            // Double delimiter → Strong
            delims[oi].closer_node_idx = info.node_idx
            delims[di].closer_node_idx = oi
            delims[oi].used = true
            delims[di].used = true

            let new_stack : Array[Int] = []
            let mut s = 0
            while s < stack.length() {
              if stack[s] != oi {
                new_stack.push(stack[s])
              }
              s = s + 1
            }
            stack = new_stack
            break
            // Length mismatch: **...* or *...**
          } else if olen == 2 && clen == 1 {
            delims[oi].closer_node_idx = info.node_idx
            delims[di].closer_node_idx = oi
            delims[oi].used = true
            delims[di].used = true

            delims[oi].length = 1
            let new_stack : Array[Int] = []
            let mut s = 0
            while s < stack.length() {
              if stack[s] != oi {
                new_stack.push(stack[s])
              }
              s = s + 1
            }
            stack = new_stack
            if delims[oi].can_open {
              stack.push(oi)
            }
            break
          } else if olen == 1 && clen == 2 {
            delims[oi].closer_node_idx = info.node_idx
            delims[di].closer_node_idx = oi
            delims[oi].used = true
            delims[di].used = true

            let new_stack : Array[Int] = []
            let mut s = 0
            while s < stack.length() {
              if stack[s] != oi {
                new_stack.push(stack[s])
              }
              s = s + 1
            }
            stack = new_stack
            break
          }
        }
        si = si - 1
      }
    }

    // If can open, add to stack
    if info.can_open && !info.used {
      stack.push(di)
    }

    di = di + 1
  }

  // Step 3: Walk nodes and produce final output
  let result : Array[Inline] = []
  let mut delim_idx = 0
  let mut ni = 0
  while ni < nodes.length() {
    match nodes[ni] {
      Final(inline) => {
        result.push(inline)
        ni = ni + 1
      }
      Delim(d) => {
        let info = delims[delim_idx]

        if info.used &&
          info.closer_node_idx >= 0 &&
          info.node_idx < info.closer_node_idx {
          // Opener with matching closer
          let closer_ni = info.closer_node_idx

          // Find closer's delimiter info
          let mut cdi = 0
          while cdi < delims.length() {
            if delims[cdi].node_idx == closer_ni {
              break
            }
            cdi = cdi + 1
          }

          // Determine Emphasis or Strong
          let olen = info.length
          let clen = if cdi < delims.length() {
            delims[cdi].length
          } else {
            olen
          }
          let is_strong = olen == 2 && clen == 2

          // Collect inner nodes between opener and closer
          let inner_nodes : Array[InlineNode] = []
          let mut inner_ni = ni + 1
          while inner_ni < closer_ni {
            inner_nodes.push(nodes[inner_ni])
            inner_ni = inner_ni + 1
          }

          // Recursively resolve inner content
          let inner_result = resolve_emphasis(inner_nodes)

          if is_strong {
            result.push(Strong(inner_result))
          } else {
            result.push(Emphasis(inner_result))
          }

          // Skip to after the closer
          ni = closer_ni + 1
          delim_idx = delim_idx + 1

          // Advance delim_idx past all delimiters up to and including closer
          while delim_idx < delims.length() {
            if delims[delim_idx].node_idx <= closer_ni {
              delim_idx = delim_idx + 1
            } else {
              break
            }
          }
        } else if info.used &&
          info.closer_node_idx >= 0 &&
          info.closer_node_idx < info.node_idx {
          // Closer (already handled by opener) → skip
          delim_idx = delim_idx + 1
          ni = ni + 1
        } else {
          // Unmatched delimiter → render as text
          let ch_str = if d.char == 42 { "*" } else { "_" }
          let mut cnt = 0
          while cnt < d.length {
            result.push(Text(ch_str))
            cnt = cnt + 1
          }
          delim_idx = delim_idx + 1
          ni = ni + 1
        }
      }
    }
  }

  result
}
