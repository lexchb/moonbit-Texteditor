///|
/// Escape HTML special characters in a string.
pub fn escape_html(s : String) -> String {
  let buf = StringBuilder()
  let mut i = 0
  while i < s.length() {
    let code = s[i]
    if code == 38 { // '&'
      buf.write_string("&amp;")
    } else if code == 60 { // '<'
      buf.write_string("&lt;")
    } else if code == 62 { // '>'
      buf.write_string("&gt;")
    } else if code == 34 { // '"'
      buf.write_string("&quot;")
    } else {
      // Append single character using string slice
      buf.write_string(s[i:i + 1].to_owned())
    }
    i = i + 1
  }
  buf.to_string()
}

///|
/// Check if a string starts with a given prefix.
pub fn starts_with(s : String, prefix : String) -> Bool {
  if prefix.length() > s.length() {
    return false
  }
  let mut i = 0
  while i < prefix.length() {
    if s[i] != prefix[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Check if a string consists entirely of the same character.
pub fn is_all_same_char(s : String, ch : UInt16) -> Bool {
  if s.length() == 0 {
    return false
  }
  let mut i = 0
  while i < s.length() {
    if s[i] != ch {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Trim trailing whitespace from a string.
pub fn trim_end(s : String) -> String {
  let mut end = s.length() - 1
  while end >= 0 {
    let ch = s[end]
    if ch != 32 && ch != 9 && ch != 13 { // ' ', '\t', '\r'
      break
    }
    end = end - 1
  }
  if end < 0 {
    return ""
  }
  s[:end + 1].to_owned()
}

///|
/// Parse an integer from a digit-only string.
pub fn parse_int(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  while i < s.length() {
    result = result * 10 + (s[i] - 48).to_int()
    i = i + 1
  }
  result
}
