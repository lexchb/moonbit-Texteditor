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

///|
/// Create a MarkdownOptions with custom settings.
/// Pass `true` to enable each feature.
pub fn create_markdown_options(
  enable_gfm_tables : Bool,
  enable_gfm_tasklist : Bool,
  enable_gfm_strikethrough : Bool,
  enable_gfm_autolink : Bool,
  enable_syntax_highlight : Bool,
  hard_wrap : Bool,
) -> MarkdownOptions {
  MarkdownOptions::{
    enable_gfm_tables,
    enable_gfm_tasklist,
    enable_gfm_strikethrough,
    enable_gfm_autolink,
    enable_syntax_highlight,
    hard_wrap,
  }
}
