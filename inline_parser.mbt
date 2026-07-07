///|
/// Parse a string containing inline content into an array of Inline nodes.
/// Phase 1 supports: Text, Code.
/// Emphasis, Link, Image, etc will be added in Phase 2.
pub fn parse_inlines(text : String) -> Array[Inline] {
  // Delegate to the shared parsing function in block_parser
  // This avoids circular dependency
  parse_inlines_simple(text)
}

///|
/// Parse inline content with full feature set (including Phase 2+ features).
pub fn parse_inlines_full(
  text : String,
  _opts : MarkdownOptions,
) -> Array[Inline] {
  // Phase 1: same as simple parser
  // Phase 2+: add emphasis, link, image, etc.
  parse_inlines_simple(text)
}
