///|
/// Simple syntax highlighter for code blocks.
/// Supports common languages: rust, javascript, python, html, css, java, c, cpp, go, json, yaml.
/// Wraps tokens in <span class="hl-{type}"> tags.

///|
/// Check if a character is an ASCII letter.
fn is_alpha(ch : UInt16) -> Bool {
  (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)
}

///|
/// Check if a character is a digit.
fn is_digit(ch : UInt16) -> Bool {
  ch >= 48 && ch <= 57
}

///|
/// Check if a character is alphanumeric or underscore.
fn is_word_char(ch : UInt16) -> Bool {
  is_alpha(ch) || is_digit(ch) || ch == 95 || ch == 36
}

///|
/// Language-specific keyword sets.
fn get_keywords(lang : String) -> Array[String] {
  let lower = lang.to_lower()
  if lower == "rust" || lower == "rs" {
    [
      "as", "break", "const", "continue", "crate", "else", "enum", "extern", "false",
      "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut",
      "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait",
      "true", "type", "unsafe", "use", "where", "while", "async", "await", "dyn",
    ]
  } else if lower == "javascript" ||
    lower == "js" ||
    lower == "typescript" ||
    lower == "ts" {
    [
      "async", "await", "break", "case", "catch", "class", "const", "continue", "debugger",
      "default", "delete", "do", "else", "export", "extends", "false", "finally",
      "for", "function", "if", "import", "in", "instanceof", "let", "new", "null",
      "of", "return", "super", "switch", "this", "throw", "true", "try", "typeof",
      "undefined", "var", "void", "while", "with", "yield",
    ]
  } else if lower == "python" || lower == "py" {
    [
      "and", "as", "assert", "async", "await", "break", "class", "continue", "def",
      "del", "elif", "else", "except", "False", "finally", "for", "from", "global",
      "if", "import", "in", "is", "lambda", "None", "nonlocal", "not", "or", "pass",
      "raise", "return", "True", "try", "while", "with", "yield",
    ]
  } else if lower == "go" {
    [
      "break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough",
      "for", "func", "go", "goto", "if", "import", "interface", "map", "package",
      "range", "return", "select", "struct", "switch", "type", "var",
    ]
  } else if lower == "java" ||
    lower == "c" ||
    lower == "cpp" ||
    lower == "c++" ||
    lower == "csharp" ||
    lower == "cs" {
    [
      "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
      "class", "const", "continue", "default", "do", "double", "else", "enum", "extends",
      "false", "final", "finally", "float", "for", "goto", "if", "implements", "import",
      "instanceof", "int", "interface", "long", "native", "new", "null", "package",
      "private", "protected", "public", "return", "short", "static", "strictfp",
      "super", "switch", "synchronized", "this", "throw", "throws", "transient",
      "true", "try", "void", "volatile", "while",
    ]
  } else if lower == "html" || lower == "xml" || lower == "svg" {
    // HTML/XML keywords are tag names
    []
  } else if lower == "css" {
    ["@import", "@media", "@keyframes", "@font-face", "!important"]
  } else if lower == "yaml" || lower == "yml" {
    []
  } else if lower == "json" {
    []
  } else if lower == "moonbit" || lower == "mbt" {
    [
      "fn", "let", "mut", "if", "else", "match", "while", "for", "in", "return",
      "true", "false", "pub", "priv", "enum", "struct", "trait", "type", "impl",
      "Self", "self", "as", "use", "open", "raise", "try", "catch", "guard", "loop",
      "break", "continue", "const", "ref", "override", "extern", "inline", "alloc",
    ]
  } else {
    // Default: common programming keywords
    [
      "if", "else", "for", "while", "do", "return", "break", "continue", "fn", "function",
      "let", "var", "const", "true", "false", "null", "undefined", "class", "struct",
      "enum", "trait", "impl", "pub", "priv", "static", "void", "int", "bool", "char",
      "float", "double", "string", "import", "from", "as", "new", "this", "super",
      "try", "catch", "throw", "raise", "match", "type", "interface", "abstract",
      "extends", "implements",
    ]
  }
}

///|
/// Check if a string is a keyword for the given language.
fn is_keyword(word : String, lang : String) -> Bool {
  let keywords = get_keywords(lang)
  for kw in keywords {
    if kw == word {
      return true
    }
  }
  false
}

///|
/// Check if lang is a language that uses // and /* */ comments.
fn has_line_comment(lang : String) -> Bool {
  let lower = lang.to_lower()
  lower != "python" && lower != "py" && lower != "yaml" && lower != "yml"
}

///|
/// Check if lang uses # for comments.
fn has_hash_comment(lang : String) -> Bool {
  let lower = lang.to_lower()
  lower == "python" ||
  lower == "py" ||
  lower == "yaml" ||
  lower == "yml" ||
  lower == "ruby" ||
  lower == "rb" ||
  lower == "sh" ||
  lower == "bash" ||
  lower == "shell" ||
  lower == "makefile" ||
  lower == "make"
}

///|
/// Check if the language uses <!-- --> HTML-style comments.
fn has_html_comment(lang : String) -> Bool {
  let lower = lang.to_lower()
  lower == "html" || lower == "xml" || lower == "svg"
}

///|
/// Highlight source code for a given language.
pub fn highlight_code(code : String, lang : String) -> String {
  let buf = StringBuilder()
  let n = code.length()
  let mut i = 0
  let lower_lang = lang.to_lower()
  let line_comment = has_line_comment(lang)
  let hash_comment = has_hash_comment(lang)
  let html_comment = has_html_comment(lang)

  while i < n {
    let ch = code[i]

    // Multi-line comment: /* ... */
    if ch == 47 && i + 1 < n && code[i + 1] == 42 {
      let mut j = i + 2
      while j < n {
        if code[j] == 42 && j + 1 < n && code[j + 1] == 47 {
          j = j + 2
          break
        }
        j = j + 1
      }
      buf.write_string("<span class=\"hl-comment\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Line comment: //
    } else if line_comment && ch == 47 && i + 1 < n && code[i + 1] == 47 {
      let mut j = i
      while j < n && code[j] != 10 {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-comment\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Hash comment: #
    } else if hash_comment && ch == 35 {
      let mut j = i
      while j < n && code[j] != 10 {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-comment\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // HTML comment: <!-- -->
    } else if html_comment &&
      ch == 60 &&
      i + 3 < n &&
      code[i:i + 4].to_owned() == "<!--" {
      let mut j = i + 4
      while j + 2 < n {
        if code[j:j + 3].to_owned() == "-->" {
          j = j + 3
          break
        }
        j = j + 1
      }
      buf.write_string("<span class=\"hl-comment\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Double-quoted string: "..."
    } else if ch == 34 {
      let mut j = i + 1
      while j < n && code[j] != 34 {
        if code[j] == 92 && j + 1 < n { // '\'
          j = j + 1
        }
        j = j + 1
      }
      if j < n {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-string\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Single-quoted string: '...'
    } else if ch == 39 {
      let mut j = i + 1
      while j < n && code[j] != 39 {
        if code[j] == 92 && j + 1 < n { // '\'
          j = j + 1
        }
        j = j + 1
      }
      if j < n {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-string\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Backtick string: `...` (shell, ruby, etc.)
    } else if ch == 96 {
      let mut j = i + 1
      while j < n && code[j] != 96 {
        j = j + 1
      }
      if j < n {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-string\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Number: digits (possibly with decimal point)
    } else if is_digit(ch) || (ch == 46 && i + 1 < n && is_digit(code[i + 1])) {
      let mut j = i
      let mut had_dot = false
      if ch == 46 {
        had_dot = true
        j = j + 1
      }
      while j < n && (is_digit(code[j]) || (!had_dot && code[j] == 46)) {
        if code[j] == 46 {
          had_dot = true
        }
        j = j + 1
      }
      // Check for hex prefix 0x
      if ch == 48 && j > i && (code[j] == 120 || code[j] == 88) {
        j = j + 1
        while j < n &&
              (
                (code[j] >= 48 && code[j] <= 57) ||
                (code[j] >= 65 && code[j] <= 70) ||
                (code[j] >= 97 && code[j] <= 102)
              ) {
          j = j + 1
        }
      }
      buf.write_string("<span class=\"hl-number\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Word: possible keyword or type
    } else if is_alpha(ch) || ch == 95 || ch == 64 || ch == 36 {
      let mut j = i
      while j < n && is_word_char(code[j]) {
        j = j + 1
      }
      let word = code[i:j].to_owned()
      if is_keyword(word, lang) {
        buf.write_string("<span class=\"hl-keyword\">")
        buf.write_string(escape_html(word))
        buf.write_string("</span>")
      } else if j > i + 0 &&
        word[0] >= 65 &&
        word[0] <= 90 &&
        !is_keyword(word, lang) &&
        word.length() > 1 {
        // Capitalized word → likely a type name
        buf.write_string("<span class=\"hl-type\">")
        buf.write_string(escape_html(word))
        buf.write_string("</span>")
      } else {
        buf.write_string(escape_html(word))
      }
      i = j
      // HTML/XML tags: <tagname ...>
    } else if ch == 60 &&
      (lower_lang == "html" || lower_lang == "xml" || lower_lang == "svg") {
      let mut j = i + 1
      // Tag name
      while j < n && code[j] != 62 && code[j] != 10 {
        if code[j] == 34 || code[j] == 39 {
          let quote = code[j]
          j = j + 1
          while j < n && code[j] != quote {
            j = j + 1
          }
          if j < n {
            j = j + 1
          }
        } else {
          j = j + 1
        }
      }
      if j < n && code[j] == 62 {
        j = j + 1
      }
      buf.write_string("<span class=\"hl-keyword\">")
      buf.write_string(escape_html(code[i:j].to_owned()))
      buf.write_string("</span>")
      i = j
      // Newline
    } else if ch == 10 {
      buf.write_string("\n")
      i = i + 1
      // Other characters (operators, punctuation, whitespace)
    } else {
      buf.write_string(escape_html(code[i:i + 1].to_owned()))
      i = i + 1
    }
  }

  buf.to_string()
}
