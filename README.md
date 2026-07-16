# moonbit-texteditor

基于 MoonBit 语言的 **Markdown to HTML** 转换工具库。

## 项目定位

一个纯 MoonBit 编写的 Markdown 解析与 HTML 渲染库，为 MoonBit 生态提供文档渲染能力。开发者可将其集成到 Web 应用、静态站点生成器、代码编辑器预览面板等场景中。

### 与赛题要求的对应

- **明确功能**：Markdown → HTML 完整转换链路
- **真实使用场景**：文档站、博客、README 预览、编辑器实时渲染
- **可复用价值**：生态中尚无纯 MoonBit 的 Markdown 渲染库，可作为 Luna UI / Sol SSG 等框架的底层依赖
- **代码量目标**：4~10k 有效 MoonBit 代码行

---

## 一、功能范围

### 第一阶段：CommonMark 核心语法（必做）

| 语法 | 示例 | 优先级 |
|------|------|--------|
| **标题** | `# H1` ~ `###### H6` | P0 |
| **段落** | 连续文本块 | P0 |
| **换行** | 行尾双空格 / 空行分段 | P0 |
| **强调** | `*italic*` `**bold**` | P0 |
| **代码** | 行内 `` `code` ``、代码块（缩进/围栏 ` ``` `） | P0 |
| **链接** | `[text](url)` `[text](url "title")` | P0 |
| **图片** | `![alt](src)` | P0 |
| **无序列表** | `- item` / `* item` / `+ item` | P0 |
| **有序列表** | `1. item` | P0 |
| **块引用** | `> quote`（支持嵌套） | P0 |
| **水平线** | `---` `***` `___` | P0 |
| **转义** | `\*` `\[` 等反斜杠转义 | P0 |
| **HTML 原样输出** | 内联 `<span>`、块级 `<div>` | P0 |

### 第二阶段：GFM 扩展语法

| 语法 | 示例 | 优先级 |
|------|------|--------|
| **表格** | 管道符表格 `\| A \| B \|` | P1 |
| **任务列表** | `- [x] done` `- [ ] todo` | P1 |
| **删除线** | `~~strikethrough~~` | P1 |
| **围栏代码块语言标注** | ```` ```rust ```` | P1 |
| **自动链接** | `https://example.com` | P1 |

### 第三阶段：增强功能

| 功能 | 说明 | 优先级 |
|------|------|--------|
| **语法高亮** | 代码块输出带 `<span class="hl-*">` 包裹 | P2 |
| **TOC 生成** | 根据标题生成目录结构 | P2 |
| **元数据解析** | 支持 Frontmatter (`---\ntitle: ...\n---`) | P2 |
| **脚注** | `[^1]` 风格脚注 | P2 |
| **自定义容器** | `::: tip` / `::: warning` | P2 |

---

## 安装与使用

### 环境要求

- [MoonBit CLI](https://docs.moonbitlang.com/)（推荐最新稳定版）
- Git

### 安装方式

**方式一：作为 MoonBit 项目依赖（推荐）**

在目标项目的 `moon.pkg` 中添加依赖：

```toml
import {
  "moonbit-texteditor/src" @md,
}
```

然后运行 `moon update` 自动拉取。如果包已发布到 [mooncakes.io](https://mooncakes.io/)：

```bash
moon add moonbit-texteditor
```

**方式二：从源码构建**

```bash
git clone https://github.com/lexchb/moonbit-Texteditor.git
cd moonbit-Texteditor
moon build            # 构建原生目标
moon build --target js   # 构建 JS 目标（浏览器使用）
```

### 运行示例

**CLI 演示程序** — 展示所有支持的 Markdown 功能：

```bash
moon run cmd/main
```

**Web 交互式演示** — 实时 Markdown 编辑器：

直接在浏览器中打开项目根目录下的 [`demo.html`](demo.html)（需要本地 HTTP 服务器）：

```bash
# Python
python -m http.server 8000

# Node.js
npx serve .

# 然后访问 http://localhost:8000/demo.html
```

### 使用方法

本库提供从 `parse`（解析）到 `render`（渲染）的完整转换链路。

#### 基础用法 — 一句话转换

```moonbit
let html = @md.render_to_string("# Hello World")
// => "<h1>Hello World</h1>"
```

#### 带选项用法 — 控制 GFM 扩展开关

```moonbit
let opts = @md.create_markdown_options(
  true,   // enable_gfm_tables
  true,   // enable_gfm_tasklist
  true,   // enable_gfm_strikethrough
  true,   // enable_gfm_autolink
  true,   // enable_syntax_highlight
  false,  // hard_wrap
)
let html = @md.render_to_string_with_opts("~~text~~", opts)
// => "<p><del>text</del></p>"
```

#### 分步用法 — 解析 AST → 手动处理 → 自定义渲染

```moonbit
// 第一步：解析 Markdown 为 AST
let blocks = @md.parse("## Title\n\nSome **bold** text")

// 第二步：手动检查和操作 AST
match blocks[0] {
  Heading(level, inlines) => println("Heading level: " + level.to_string())
  _ => ()
}

// 第三步：渲染为 HTML
let html = @md.render(blocks)
```

#### 解析 Frontmatter 元数据

```moonbit
let input = "---\ntitle: My Doc\nauthor: Alice\n---\n\n# Content"
let (metadata, body) = @md.parse_frontmatter(input)
// metadata = [("title", "My Doc"), ("author", "Alice")]
// body     = "# Content"
```

#### 生成目录 (TOC)

```moonbit
let blocks = @md.parse("# A\n\n## B\n\n### C")
let toc = @md.generate_toc(blocks)
// toc = [(1, "A"), (2, "B"), (3, "C")]
```

#### 语法高亮（单独使用）

```moonbit
let highlighted = @md.highlight_code("fn main() {}", "rust")
// => "<span class=\"hl-keyword\">fn</span> main() {}"
```

### 完整示例

```moonbit
fn main {
  let input = "# Markdown 示例\n\n" +
    "这是一个包含 **加粗** 和 *斜体* 的段落。\n\n" +
    "| 表格 | 列2 |\n" +
    "|------|-----|\n" +
    "| 单元格1 | 单元格2 |\n\n" +
    "- [x] 已完成任务\n" +
    "- [ ] 未完成任务\n"

  // 创建选项：启用表格、任务列表、删除线
  let opts = @md.create_markdown_options(
    true, true, true, true, true, false,
  )
  let html = @md.render_to_string_with_opts(input, opts)
  println(html)
}
```

### API 速查

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `parse(input)` | `String` | `Array[Block]` | 解析为 AST |
| `parse_with_opts(input, opts)` | `String, MarkdownOptions` | `Array[Block]` | 带选项解析 |
| `render(blocks)` | `Array[Block]` | `String` | AST → HTML |
| `render_to_string(input)` | `String` | `String` | 一站式转换（默认选项） |
| `render_to_string_with_opts(input, opts)` | `String, MarkdownOptions` | `String` | 带选项一站式转换 |
| `render_html_with_opts(blocks, opts)` | `Array[Block], MarkdownOptions` | `String` | 带选项渲染 |
| `parse_frontmatter(input)` | `String` | `(Array[(String,String)], String)` | 解析 Frontmatter |
| `generate_toc(blocks)` | `Array[Block]` | `Array[(Int, String)]` | 生成目录（标题层级, 标题文本） |
| `create_markdown_options(...)` | `6 × Bool` | `MarkdownOptions` | 创建解析选项 |
| `default_options()` | — | `MarkdownOptions` | 默认选项（全部关闭） |
| `highlight_code(code, lang)` | `String, String` | `String` | 代码语法高亮 |
| `escape_html(s)` | `String` | `String` | HTML 转义 |

---

## 二、架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────┐
│                     用户 API                         │
│   parse() / render() / render_to_string()            │
├─────────────────────────────────────────────────────┤
│                 Option 层 (扩展语法)                   │
│  GFM 表格 / 任务列表 / 删除线 / 语法高亮                │
├─────────────────────────────────────────────────────┤
│                  InlineParser                        │
│  强调 / 代码 / 链接 / 图片 / HTML / 转义 / 自动链接     │
├─────────────────────────────────────────────────────┤
│                  BlockParser                         │
│  标题 / 段落 / 列表 / 代码块 / 引用 / 水平线 / 表格     │
├─────────────────────────────────────────────────────┤
│                  Tokenizer / Lexer                   │
│  行级分块 / 围栏检测 / 缩进分析 / 转义预处理             │
├─────────────────────────────────────────────────────┤
│                     AST 类型定义                       │
│  Block / Inline 枚举体系                              │
└─────────────────────────────────────────────────────┘
```

### 模块划分

```
moonbit-texteditor/
├── moon.mod.json                 # 项目配置
├── src/
│   ├── moon.pkg.json             # 包配置
│   ├── ast.mbt                   # AST 类型定义（核心数据结构）
│   ├── lexer.mbt                 # 词法分析：行分类、缩进计算、围栏检测
│   ├── block_parser.mbt          # 块级解析器
│   ├── inline_parser.mbt         # 内联解析器
│   ├── renderer_html.mbt         # HTML 渲染器
│   ├── renderer.mbt              # 渲染器 trait 定义（方便扩展其他输出）
│   ├── options.mbt               # 解析选项配置
│   ├── syntax_highlight.mbt      # 语法高亮引擎
│   ├── lib.mbt                   # 统一入口 API
│   └── utils.mbt                 # 工具函数
├── cmd/main/
│   ├── moon.pkg.json             # CLI demo 包配置
│   └── main.mbt                  # CLI 演示程序（13 个功能场景）
├── web/
│   ├── moon.pkg.json             # Web 包配置
│   └── main.mbt                  # 浏览器端 JS 桥接入口
├── demo.html                     # 交互式 Web 演示页面
└── .github/workflows/
    ├── ci.yml                    # CI（check / build / test）
    └── copilot-setup-steps.yml   # Copilot 环境配置
```

### 核心数据结构设计

```moonbit
// === Block 节点类型 ===
enum Block {
  // 文档根节点
  Document(Array[Block])
  // 段落
  Paragraph(Array[Inline])
  // 标题 (level: 1-6)
  Heading(Int, Array[Inline])
  // 无序列表
  BulletList(Array[ListItem], Bool)  // 是否紧凑
  // 有序列表
  OrderedList(Array[ListItem], Int, Bool)  // 起始序号, 是否紧凑
  // 列表项
  ListItem(Bool, Array[Block])  // 是否已勾选（任务列表）
  // 代码块（围栏式）
  FencedCodeBlock(String?, String)  // 语言, 内容
  // 代码块（缩进式）
  IndentedCodeBlock(String)
  // 块引用
  BlockQuote(Array[Block])
  // 水平线
  ThematicBreak
  // HTML 块
  HtmlBlock(String)
  // 表格（GFM）
  Table(Array[TableRow])
  // 空行
  BlankLine
}

// === Inline 节点类型 ===
enum Inline {
  // 纯文本
  Text(String)
  // 软换行
  SoftBreak
  // 硬换行
  LineBreak
  // 斜体
  Emphasis(Array[Inline])
  // 加粗
  Strong(Array[Inline])
  // 删除线（GFM）
  Strikethrough(Array[Inline])
  // 行内代码
  Code(String)
  // 链接
  Link(Array[Inline], String, String?)  // 文本, URL, title
  // 图片
  Image(String, String, String?)  // alt, src, title
  // HTML 内联
  HtmlInline(String)
  // 自动链接
  AutoLink(String, Bool)  // URL / Email
}
```

---

## 三、各模块详细说明

### 3.1 AST 类型定义 (`ast.mbt`)

- 定义完整的 `Block` 和 `Inline` 枚举体系
- 提供 `Show` trait 实现，方便调试输出
- 预计代码量：~0.5k

### 3.2 词法分析器 (`lexer.mbt`)

- 将原始 Markdown 文本按行切割
- 对每一行进行分类：标题行、列表项、围栏标记、空行、缩进代码块、普通文本等
- 计算缩进层级，用于列表嵌套判断
- 预处理反斜杠转义

```moonbit
enum LineType {
  Heading(Int)       // # ## ### ...
  FenceStart(String?) // ``` 或 ~~~，可选语言
  FenceEnd
  BulletItem(String)  // - * +
  OrderedItem(Int)    // 1.
  BlockQuote
  ThematicBreak
  Empty
  IndentedCode
  TableRow
  Paragraph
}

struct Line {
  typ : LineType
  content : String
  indent : Int
  line_number : Int
}
```

- 预计代码量：~1.0k

### 3.3 块级解析器 (`block_parser.mbt`)

- 将 `Line[]` 转换为 `Block[]`（AST）
- 核心挑战：列表嵌套、引用嵌套、代码块边界检测
- 采用**递归下降**方式解析块级结构

```moonbit
struct BlockParser {
  lines : Array[Line]
  mut pos : Int
}

fn parse(lines : Array[Line]) -> Array[Block]
```

- 预计代码量：~2.0k

### 3.4 内联解析器 (`inline_parser.mbt`)

- 将块中的文本字符串解析为 `Array[Inline]`
- 按优先级处理：转义 > HTML > 图片 > 链接 > 代码 > 强调 > 文本
- 强调解析采用 **CommonMark 规定的 delimiter 规则**（最复杂部分）

```moonbit
struct Delimiter {
  char : Char        // * 或 _
  is_close : Bool
  is_open : Bool
  position : Int
  length : Int       // 1 或 2
}
```

- 预计代码量：~2.5k（强调解析占大头）

### 3.5 HTML 渲染器 (`renderer_html.mbt`)

- 遍历 AST 生成 HTML 字符串
- 使用 `StringBuilder`（MoonBit v0.10 已有）高效拼接
- 支持 v0.10 新增的模板写入语法 `<+` 提升可读性

```moonbit
fn render_block(block : Block, buf : StringBuilder) -> Unit
fn render_inline(inline : Inline, buf : StringBuilder) -> Unit
```

- 预计代码量：~1.5k

### 3.6 选项系统 (`options.mbt`)

```moonbit
struct MarkdownOptions {
  // 启用/禁用特定语法
  enable_gfm_tables : Bool = false
  enable_gfm_tasklist : Bool = false
  enable_gfm_strikethrough : Bool = false
  enable_gfm_autolink : Bool = false
  enable_syntax_highlight : Bool = false
  
  // 渲染选项
  line_width : Int = 80
  hard_wrap : Bool = false      // 是否将软换行转为 <br>
}
```

- 预计代码量：~0.3k

### 3.7 统一 API (`lib.mbt`)

```moonbit
/// 将 Markdown 字符串解析为 Block AST
pub fn parse(input : String) -> Array[Block]

/// 将 Block AST 渲染为 HTML 字符串
pub fn render(blocks : Array[Block]) -> String

/// 解析 + 渲染一站式调用
pub fn render_to_string(input : String) -> String

/// 带选项的解析
pub fn parse_with_opts(input : String, opts : MarkdownOptions) -> Array[Block]

/// 带选项的渲染
pub fn render_to_string_with_opts(input : String, opts : MarkdownOptions) -> String
```

- 预计代码量：~0.2k

---

## 四、代码量估算

| 模块 | 文件 | 预估代码量 |
|------|------|-----------|
| AST 类型定义 | `ast.mbt` | ~0.5k |
| 词法分析器 | `lexer.mbt` | ~1.0k |
| 块级解析器 | `block_parser.mbt` | ~2.0k |
| 内联解析器 | `inline_parser.mbt` | ~2.5k |
| HTML 渲染器 | `renderer_html.mbt` + `renderer.mbt` | ~1.5k |
| 选项系统 | `options.mbt` | ~0.3k |
| 统一 API | `lib.mbt` | ~0.2k |
| 工具函数 | `utils.mbt` | ~0.3k |
| **小计（核心）** | | **~8.3k** |
| GFM 表格 | `gfm/table.mbt` | ~0.8k |
| GFM 任务列表 | `gfm/task_list.mbt` | ~0.3k |
| GFM 删除线 | `gfm/strikethrough.mbt` | ~0.2k |
| GFM 自动链接 | `gfm/autolink.mbt` | ~0.3k |
| **小计（扩展）** | | **~1.6k** |
| 测试 | `test/*.mbt` | ~1.5k |
| 基准测试 | `bench/benchmark.mbt` | ~0.5k |
| **合计** | | **~11.9k** |

核心部分约 **8.3k** 行，不含测试为 **~9.9k**，含全部扩展约 **~11.9k**。可根据进度灵活裁剪 GFM 扩展以控制代码量在 4~10k 范围内。

---

## 五、开发路线图

### Phase 1：基础设施与核心解析（第 1~2 周）

1. 初始化 MoonBit 项目结构
2. 定义 `ast.mbt` 中的 `Block` / `Inline` 枚举
3. 实现 `lexer.mbt`：行分类 + 缩进分析
4. 实现 `block_parser.mbt` 基础能力：
   - 段落（Paragraph）
   - 标题（Heading）
   - 水平线（ThematicBreak）
   - 代码块（IndentedCodeBlock）
5. 实现 `inline_parser.mbt` 基础能力：
   - Text / SoftBreak / LineBreak
   - Code（行内代码）
   - HardBreak
6. 实现基础 HTML 渲染器

### Phase 2：核心内联语法（第 3 周）

1. 实现强调解析（Emphasis / Strong）
   - delimiter 扫描
   - delimiter 匹配（CommonMark 规范）
2. 实现链接（Link）和图片（Image）
3. 实现 HTML 内联（HtmlInline）
4. 实现反斜杠转义

### Phase 3：复杂块级结构（第 4 周）

1. 实现列表（BulletList / OrderedList）
   - 嵌套列表支持
   - 紧凑/非紧凑模式判断
2. 实现块引用（BlockQuote）
   - 嵌套引用
3. 实现围栏代码块（FencedCodeBlock）
4. 实现 HTML 块（HtmlBlock）

### Phase 4：GFM 扩展（第 5 周）

1. 表格解析（Table）
2. 任务列表（ListItem 的 checked 状态）
3. 删除线（Strikethrough）
4. 自动链接（AutoLink）
5. 选项系统集成

### Phase 5：测试与优化（第 6 周）

1. CommonMark 规范测试套件驱动测试
2. 边界情况处理（空输入、极端嵌套、大量转义）
3. 性能优化（StringBuilder 复用、减少分配）
4. Benchmark 编写
5. 文档完善

---

## 六、测试策略

### 测试层级

```
单元测试 → 集成测试 → CommonMark 规范测试
```

- **单元测试**：每个 parser 函数独立测试
- **集成测试**：Markdown 片段 → 预期 HTML 对比
- **规范测试**：从 CommonMark spec 中提取测试用例

### 测试用例覆盖

```
输入: "# Hello"
输出: "<h1>Hello</h1>"

输入: "**bold** and *italic*"
输出: "<p><strong>bold</strong> and <em>italic</em></p>"

输入: "- item 1\n- item 2"
输出: "<ul>\n<li>item 1</li>\n<li>item 2</li>\n</ul>"

输入: "> quote\n>\n> more"
输出: "<blockquote>\n<p>quote</p>\n<p>more</p>\n</blockquote>"
```

---

## 七、技术要点与风险控制

### MoonBit 特性利用

| 特性 | 用途 |
|------|------|
| `enum` + `match` | AST 节点枚举 + 模式匹配解析/渲染 |
| `StringBuilder` | 高效 HTML 拼接（MoonBit v0.10 优化） |
| `<+` 模板写入语法 | HTML 渲染时避免重复 `write_string` 调用 |
| `trait` | 渲染器接口抽象（后续可扩展 JSON / LaTeX 输出） |
| `raise` 错误处理 | 解析错误传播 |

### 潜在风险与应对

| 风险 | 应对方案 |
|------|---------|
| 强调解析实现复杂（CommonMark 规则繁琐） | 参考实现规范中的伪代码，分步实现 delimiter 处理逻辑 |
| 嵌套列表边界情况多 | 使用递归下降 + 缩进栈管理，测试覆盖所有嵌套场景 |
| 代码量不足 4k | 提前规划 GFM 扩展和语法高亮作为"代码量缓冲" |
| MoonBit API 版本变化 | 锁定月亮版本，关注更新日志，统一适配 |

---

## 原创或移植说明

本项目基于 **CommonMark 0.31 规范** 和 **GitHub Flavored Markdown (GFM) 规范** 使用 MoonBit 语言进行原创实现。

### 参考来源

| 项目名称 | 链接 | 许可证 | 参考内容 |
|---------|------|--------|---------|
| CommonMark Spec | `https://spec.commonmark.org/0.31/` | CC-BY-SA 4.0 | 语法规则、解析算法伪代码、测试用例 |

本项目的解析逻辑直接基于 CommonMark 规范文档中的算法描述实现，未直接复制或移植任何现有开源项目的源代码。

### 本项目许可证

Apache License 2.0

### 设计与实现特点

- 使用 MoonBit 原生包结构、`enum` + `match` 类型系统和测试方式组织代码，而不是复刻 C/JavaScript 的函数式风格；
- 优先实现可在 MoonBit 中独立运行的核心解析能力，弱化对外部运行时或动态链接库的依赖；
- 对 CommonMark 规范中的 edge case（如嵌套强调、围栏代码块结束规则、列表紧凑模式判断）严格实现；
- 对字符串处理和正则表达式等机制进行 MoonBit 化改写，使用 `StringBuilder` 和模式匹配替代；
- 以 HTML 输出和 MoonBit API 为主要交付接口，方便接入 Web、CLI、IDE 和可视化渲染场景。
