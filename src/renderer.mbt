///|
/// Trait for rendering Markdown AST to different output formats.
pub(open) trait Renderer {
  /// Render a list of block-level nodes to output format.
  fn render_blocks(Self, Array[Block], StringBuilder) -> Unit

  /// Render a list of inline-level nodes to output format.
  fn render_inlines(Self, Array[Inline], StringBuilder) -> Unit
}
