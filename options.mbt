///|
/// Options for configuring the Markdown parser and renderer.
pub struct MarkdownOptions {
  /// Enable GFM table syntax
  enable_gfm_tables : Bool
  /// Enable GFM task list syntax
  enable_gfm_tasklist : Bool
  /// Enable GFM strikethrough syntax
  enable_gfm_strikethrough : Bool
  /// Enable GFM autolink syntax
  enable_gfm_autolink : Bool
  /// Enable syntax highlighting for code blocks
  enable_syntax_highlight : Bool
  /// Render soft breaks as <br> (hard wrap)
  hard_wrap : Bool
}

///|
/// Default options (all extensions disabled).
pub fn default_options() -> MarkdownOptions {
  MarkdownOptions::{
    enable_gfm_tables: false,
    enable_gfm_tasklist: false,
    enable_gfm_strikethrough: false,
    enable_gfm_autolink: false,
    enable_syntax_highlight: false,
    hard_wrap: false,
  }
}
