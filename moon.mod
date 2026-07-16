name = "lexchb/moonbit-texteditor"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/lexchb/moonbit-Texteditor"

license = "Apache-2.0"

keywords = [ "markdown", "html", "parser", "renderer" ]

preferred_target = "wasm-gc"

description = "A pure MoonBit Markdown to HTML conversion library."

options(
  exclude: ["cmd", "web", "demo.html", "web.editor.js", "_build", ".github", "AGENTS.md"],
)
