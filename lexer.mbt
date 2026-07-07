///|
/// Classified line types from the raw input.
pub enum LineType {
  /// ATX heading with level (1-6)
  Heading(Int)
  /// Fenced code block start (optional language)
  FenceStart(String?)
  /// Fenced code block end
  FenceEnd
  /// Unordered list item marker (-, *, +)
  BulletItem(String)
  /// Ordered list item marker (number followed by .)
  OrderedItem(Int)
  /// Block quote marker (>)
  BlockQuote
  /// Thematic break
  ThematicBreak
  /// Empty line
  Empty
  /// Indented code block (4 spaces or 1 tab)
  IndentedCode
  /// Table row (GFM)
  TableRow
  /// Regular paragraph text
  Paragraph
}

///|
/// A single classified line from the input.
pub struct Line {
  typ : LineType
  content : String
  indent : Int
  line_number : Int
  raw : String
}

///|
/// Split raw text into lines.
fn split_lines(input : String) -> Array[String] {
  let lines : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < input.length() {
    let ch = input[i]
    if ch == 13 { // '\r'
      let line = input[start:i].to_owned()
      lines.push(line)
      if i + 1 < input.length() && input[i + 1] == 10 { // '\n'
        i = i + 1
      }
      start = i + 1
    } else if ch == 10 { // '\n'
      let line = input[start:i].to_owned()
      lines.push(line)
      start = i + 1
    }
    i = i + 1
  }
  // Last line
  if start < input.length() {
    let line = input[start:input.length()].to_owned()
    lines.push(line)
  }
  lines
}

///|
/// Calculate indentation level (number of leading spaces/tabs).
fn count_indent(line : String) -> Int {
  let mut count = 0
  let mut i = 0
  while i < line.length() {
    let ch = line[i]
    if ch == 32 { // ' '
      count = count + 1
    } else if ch == 9 { // '\t'
      count = count + 4
    } else {
      break
    }
    i = i + 1
  }
  count
}

///|
/// Strip leading whitespace (indentation) from a string.
fn strip_indent(s : String) -> String {
  let mut start = 0
  while start < s.length() {
    let ch = s[start]
    if ch != 32 && ch != 9 { // ' ', '\t'
      break
    }
    start = start + 1
  }
  s[start:s.length()].to_owned()
}

///|
/// Check if a string is a thematic break (---, ***, ___ with optional spaces).
fn is_thematic_break(s : String) -> Bool {
  if s.length() < 3 {
    return false
  }
  let first = s[0]
  if first != 45 && first != 42 && first != 95 { // '-', '*', '_'
    return false
  }
  let mut i = 0
  while i < s.length() {
    let ch = s[i]
    if ch != first && ch != 32 { // first char or ' '
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Check if a string is a fenced code block start.
fn is_fence_start(s : String) -> (Bool, String?) {
  if s.length() < 3 {
    return (false, None)
  }
  let first = s[0]
  if first != 96 && first != 126 { // '`', '~'
    return (false, None)
  }
  let mut i = 0
  while i < s.length() {
    if s[i] != first {
      break
    }
    i = i + 1
  }
  if i < 3 {
    return (false, None)
  }
  // Remaining part after the fence markers is the language
  let rest = s[i:s.length()].trim().to_owned()
  let lang = if rest.length() > 0 { Some(rest) } else { None }
  (true, lang)
}

///|
/// Classify a single line and return its type and content.
fn classify_line(line : String) -> (LineType, String) {
  let trimmed = line.trim().to_owned()

  // Empty line
  if trimmed.length() == 0 {
    return (Empty, "")
  }

  // Check for thematic break before heading
  if is_thematic_break(trimmed) {
    return (ThematicBreak, trimmed)
  }

  // ATX heading
  if trimmed[0] == 35 { // '#'
    let mut level = 0
    let mut i = 0
    while i < trimmed.length() && trimmed[i] == 35 { // '#'
      level = level + 1
      i = i + 1
    }
    if level <= 6 &&
      (i >= trimmed.length() || trimmed[i] == 32 || trimmed[i] == 9) { // ' ' or '\t'
      let content = if i < trimmed.length() {
        trimmed[i:trimmed.length()].trim().to_owned()
      } else {
        ""
      }
      return (Heading(level), content)
    }
  }

  // Block quote
  if trimmed[0] == 62 { // '>'
    let content = if trimmed.length() > 1 {
      let rest = trimmed[1:trimmed.length()]
      if rest.length() > 0 && rest[0] == 32 { // ' '
        rest[1:rest.length()].to_owned()
      } else {
        rest.to_owned()
      }
    } else {
      ""
    }
    return (BlockQuote, content)
  }

  // Bullet list
  if trimmed[0] == 45 || trimmed[0] == 42 || trimmed[0] == 43 { // '-', '*', '+'
    if trimmed.length() >= 2 && (trimmed[1] == 32 || trimmed[1] == 9) { // ' ' or '\t'
      let content = trimmed[2:trimmed.length()].trim().to_owned()
      return (BulletItem(trimmed[0:1].to_owned()), content)
    }
    if trimmed.length() == 1 {
      return (BulletItem(trimmed[0:1].to_owned()), "")
    }
  }

  // Ordered list
  if trimmed[0] >= 48 && trimmed[0] <= 57 { // '0'-'9'
    let mut i = 0
    while i < trimmed.length() && trimmed[i] >= 48 && trimmed[i] <= 57 {
      i = i + 1
    }
    if i > 0 && i < trimmed.length() && trimmed[i] == 46 { // '.'
      let num_str = trimmed[0:i].to_owned()
      let num = parse_int(num_str)
      let content = trimmed[i + 1:trimmed.length()].trim().to_owned()
      return (OrderedItem(num), content)
    }
  }

  // Fenced code block start/end
  let (is_fence, lang) = is_fence_start(trimmed)
  if is_fence {
    if lang is None {
      // No info string after fence markers → FenceEnd
      return (FenceEnd, trimmed)
    } else {
      return (FenceStart(lang), trimmed)
    }
  }

  // Indented code (4 spaces or 1 tab at start of non-empty line)
  if line.length() > 0 {
    let indent = count_indent(line)
    if indent >= 4 && stripped_content(line).length() > 0 {
      let content = line[4:line.length()].to_owned()
      return (IndentedCode, content)
    }
  }

  // Default: paragraph text
  (Paragraph, trimmed)
}

///|
/// Get content of a line after stripping leading whitespace.
fn stripped_content(s : String) -> String {
  strip_indent(s)
}

///|
/// Tokenize the raw Markdown input into classified lines.
pub fn tokenize(input : String) -> Array[Line] {
  let raw_lines = split_lines(input)
  let result : Array[Line] = []
  let mut line_number = 0

  for raw_line in raw_lines {
    line_number = line_number + 1
    let indent = count_indent(raw_line)
    let (typ, content) = classify_line(raw_line)
    result.push({ typ, content, indent, line_number, raw: raw_line })
  }

  result
}
