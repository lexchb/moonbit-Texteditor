///|
/// HTML Renderer implementation.
pub struct HtmlRenderer {
  options : MarkdownOptions
}

///|
/// Create a new HTML renderer with default options.
pub fn HtmlRenderer::new() -> HtmlRenderer {
  HtmlRenderer::{ options: default_options() }
}

///|
/// Create a new HTML renderer with custom options.
pub fn HtmlRenderer::new_with_opts(opts : MarkdownOptions) -> HtmlRenderer {
  HtmlRenderer::{ options: opts }
}

///|
/// Convenience: render a list of Block nodes to HTML string.
pub fn render_html(blocks : Array[Block]) -> String {
  let renderer = HtmlRenderer::new()
  renderer.render_blocks(blocks)
}

///|
/// Render a single Block node to a StringBuilder.
pub fn HtmlRenderer::render_block(
  self : HtmlRenderer,
  block : Block,
  buf : StringBuilder,
) -> Unit {
  match block {
    Document(children) =>
      for child in children {
        self.render_block(child, buf)
      }
    Paragraph(inlines) => {
      buf.write_string("<p>")
      self.render_inlines(inlines, buf)
      buf.write_string("</p>\n")
    }
    Heading(level, inlines) => {
      let tag = "h" + level.to_string()
      buf.write_string("<")
      buf.write_string(tag)
      buf.write_string(">")
      self.render_inlines(inlines, buf)
      buf.write_string("</")
      buf.write_string(tag)
      buf.write_string(">\n")
    }
    ThematicBreak => buf.write_string("<hr />\n")
    IndentedCodeBlock(code) => {
      buf.write_string("<pre><code>")
      buf.write_string(escape_html(code))
      buf.write_string("</code></pre>\n")
    }
    FencedCodeBlock(lang, code) => {
      buf.write_string("<pre><code")
      match lang {
        Some(l) => {
          buf.write_string(" class=\"language-")
          buf.write_string(escape_html(l))
          buf.write_string("\"")
        }
        None => ()
      }
      buf.write_string(">")
      let rendered = if self.options.enable_syntax_highlight {
        match lang {
          Some(l) => highlight_code(code, l)
          None => escape_html(code)
        }
      } else {
        escape_html(code)
      }
      buf.write_string(rendered)
      buf.write_string("</code></pre>\n")
    }
    BlockQuote(children) => {
      buf.write_string("<blockquote>\n")
      for child in children {
        self.render_block(child, buf)
      }
      buf.write_string("</blockquote>\n")
    }
    BulletList(items, _tight) => {
      buf.write_string("<ul>\n")
      for item in items {
        buf.write_string("<li>")
        for child in item.children {
          self.render_block(child, buf)
        }
        buf.write_string("</li>\n")
      }
      buf.write_string("</ul>\n")
    }
    OrderedList(items, _start, _tight) => {
      buf.write_string("<ol>\n")
      for item in items {
        buf.write_string("<li>")
        for child in item.children {
          self.render_block(child, buf)
        }
        buf.write_string("</li>\n")
      }
      buf.write_string("</ol>\n")
    }
    ListItem(_checked, children) => {
      buf.write_string("<li>")
      for child in children {
        self.render_block(child, buf)
      }
      buf.write_string("</li>\n")
    }
    HtmlBlock(html) => {
      buf.write_string(html)
      buf.write_string("\n")
    }
    Table(rows) => {
      buf.write_string("<table>\n")
      for row in rows {
        buf.write_string("<tr>")
        for cell in row.cells {
          buf.write_string("<td>")
          buf.write_string(escape_html(cell))
          buf.write_string("</td>")
        }
        buf.write_string("</tr>\n")
      }
      buf.write_string("</table>\n")
    }
    BlankLine => ()
    Container(name, children) => {
      buf.write_string("<div class=\"container-")
      buf.write_string(escape_html(name))
      buf.write_string("\">\n")
      for child in children {
        self.render_block(child, buf)
      }
      buf.write_string("</div>\n")
    }
    FootnoteDef(_label, children) => {
      buf.write_string("<div class=\"footnote-def\">")
      for child in children {
        self.render_block(child, buf)
      }
      buf.write_string("</div>\n")
    }
  }
}

///|
/// Render a list of Inline nodes to a StringBuilder.
pub fn HtmlRenderer::render_inlines(
  self : HtmlRenderer,
  inlines : Array[Inline],
  buf : StringBuilder,
) -> Unit {
  for inline in inlines {
    match inline {
      Text(text) => buf.write_string(escape_html(text))
      Code(code) => {
        buf.write_string("<code>")
        buf.write_string(escape_html(code))
        buf.write_string("</code>")
      }
      SoftBreak =>
        if self.options.hard_wrap {
          buf.write_string("<br />\n")
        } else {
          buf.write_string("\n")
        }
      LineBreak => buf.write_string("<br />\n")
      Emphasis(inlines_inner) => {
        buf.write_string("<em>")
        self.render_inlines(inlines_inner, buf)
        buf.write_string("</em>")
      }
      Strong(inlines_inner) => {
        buf.write_string("<strong>")
        self.render_inlines(inlines_inner, buf)
        buf.write_string("</strong>")
      }
      Strikethrough(inlines_inner) => {
        buf.write_string("<del>")
        self.render_inlines(inlines_inner, buf)
        buf.write_string("</del>")
      }
      Link(text_inlines, url, title) => {
        buf.write_string("<a href=\"")
        buf.write_string(escape_html(url))
        buf.write_string("\"")
        match title {
          Some(t) => {
            buf.write_string(" title=\"")
            buf.write_string(escape_html(t))
            buf.write_string("\"")
          }
          None => ()
        }
        buf.write_string(">")
        self.render_inlines(text_inlines, buf)
        buf.write_string("</a>")
      }
      Image(alt, src, title) => {
        buf.write_string("<img src=\"")
        buf.write_string(escape_html(src))
        buf.write_string("\" alt=\"")
        buf.write_string(escape_html(alt))
        buf.write_string("\"")
        match title {
          Some(t) => {
            buf.write_string(" title=\"")
            buf.write_string(escape_html(t))
            buf.write_string("\"")
          }
          None => ()
        }
        buf.write_string(" />")
      }
      HtmlInline(html) => buf.write_string(html)
      AutoLink(url, _is_email) => {
        buf.write_string("<a href=\"")
        buf.write_string(escape_html(url))
        buf.write_string("\">")
        buf.write_string(escape_html(url))
        buf.write_string("</a>")
      }
      FootnoteRef(label) => {
        buf.write_string("<sup><a href=\"#fn-")
        buf.write_string(escape_html(label))
        buf.write_string("\" id=\"fnref-")
        buf.write_string(escape_html(label))
        buf.write_string("\" class=\"footnote\">")
        buf.write_string(escape_html(label))
        buf.write_string("</a></sup>")
      }
    }
  }
}

///|
/// Render a list of Block nodes to HTML string (method on HtmlRenderer).
pub fn HtmlRenderer::render_blocks(
  self : HtmlRenderer,
  blocks : Array[Block],
) -> String {
  let buf = StringBuilder()
  for block in blocks {
    self.render_block(block, buf)
  }
  buf.to_string()
}
