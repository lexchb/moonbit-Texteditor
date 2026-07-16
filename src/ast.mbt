///|
/// Block-level AST node types.
pub enum Block {
  /// Root document node
  Document(Array[Block])
  /// Paragraph
  Paragraph(Array[Inline])
  /// Heading with level 1-6
  Heading(Int, Array[Inline])
  /// Unordered list (tight: compact or loose)
  BulletList(Array[ListItem], Bool)
  /// Ordered list (start: number, tight: compact or loose)
  OrderedList(Array[ListItem], Int, Bool)
  /// A list item (checked: task list state)
  ListItem(Bool, Array[Block])
  /// Fenced code block (lang: optional language identifier)
  FencedCodeBlock(String?, String)
  /// Indented code block (4 spaces / 1 tab)
  IndentedCodeBlock(String)
  /// Block quote (supports nesting)
  BlockQuote(Array[Block])
  /// Thematic break (horizontal rule)
  ThematicBreak
  /// Raw HTML block
  HtmlBlock(String)
  /// Table (GFM extension)
  Table(Array[TableRow])
  /// Blank line (separator)
  BlankLine
  /// Custom container (::: name ... :::)
  Container(String, Array[Block])
  /// Footnote definition ([^label]: content)
  FootnoteDef(String, Array[Block])
}

///|
/// Inline-level AST node types.
pub enum Inline {
  /// Plain text
  Text(String)
  /// Soft line break (treated as space in output)
  SoftBreak
  /// Hard line break (rendered as <br>)
  LineBreak
  /// Emphasis (italic)
  Emphasis(Array[Inline])
  /// Strong emphasis (bold)
  Strong(Array[Inline])
  /// Strikethrough (GFM extension)
  Strikethrough(Array[Inline])
  /// Inline code
  Code(String)
  /// Hyperlink (text, url, optional title)
  Link(Array[Inline], String, String?)
  /// Image (alt text, src, optional title)
  Image(String, String, String?)
  /// Raw HTML inline
  HtmlInline(String)
  /// Autolink (url or email)
  AutoLink(String, Bool)
  /// Footnote reference (GFM extension)
  FootnoteRef(String)
}

///|
/// A list item node.
pub struct ListItem {
  checked : Bool
  children : Array[Block]
}

///|
/// A table row node.
pub struct TableRow {
  cells : Array[String]
}
