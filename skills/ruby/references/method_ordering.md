# Method Ordering & File Layout

**Principle:** A Ruby file should read like a newspaper — top-level intent first, mechanism below — so a reader descends exactly one level of abstraction at a time. This is the *stepdown rule* (Robert C. Martin, *Clean Code*) applied with a deliberate Ruby twist: group methods by **abstraction altitude**, not by the feature or caller that introduces them.

## File layout order

Top to bottom in a class or module:

1. `extend` / `include` / `prepend`
2. Constants (`MAX_RETRIES = 3`)
3. `attr_reader` / `attr_accessor` and class-level macros (`belongs_to`, `validates`, `scope`)
4. `def initialize`
5. Public methods — highest-level entry points first, supporting public methods after
6. `protected` methods
7. `private` methods — helpers, ordered by altitude (see below)

Put the `attr_reader` for purely internal state just under `private` when the readers are an implementation detail rather than part of the public API.

## The core rule: breadth-first, not depth-first

Picture the call graph as a tree. Public entry points are the roots; each helper a method calls sits one level deeper.

- **Breadth-first (do this):** emit every method at altitude *N* before any method at altitude *N+1*. All the sibling steps sit together; all of their helpers sit together below them.
- **Depth-first (avoid this):** emit a method, then immediately its helpers, then its helpers' helpers, before returning to the next sibling. Altitudes interleave and the sibling steps scatter down the file.

Named precisely, the layout you want is a **breadth-first traversal of the call tree by abstraction altitude**. It is the same idea behind the **Single Level of Abstraction Principle (SLAP)** — keep one altitude together — and the **newspaper metaphor** — headline, then summary, then detail.

> **Caveat on textbook stepdown.** *Clean Code*'s original phrasing sometimes places a callee *immediately* after its caller, which trends depth-first. This convention deliberately prefers altitude-grouping instead: it keeps the "table of contents" of each level readable in a single glance and stops one deep branch from burying its siblings.

## Worked example

A `SalesReportBuilder` with two public reports. Below is the layout an **unguided agent naturally produces** — depth-first, grouped by feature, with altitudes interleaved. The section comments are the agent's own, and they expose the problem: an altitude-3 cluster (`# totals_line helpers`) is nested inside the altitude-2 walk, then the file jumps back up to altitude 2.

```ruby
# frozen_string_literal: true

class SalesReportBuilder
  def initialize(sales) = @sales = sales

  def summary_report  = [summary_header, totals_line, top_performers_line].join("\n")
  def detailed_report = [detailed_header, per_region_table, detailed_footer].join("\n")

  private

  attr_reader :sales

  # --- summary_report parts ---            (altitude 2)
  def summary_header      = "=== Sales Summary ==="
  def totals_line         = "Totals: gross #{format_money(total_gross)}, net #{format_money(total_net)}"
  def top_performers_line = "Top: #{top_performers.join(', ')}"

  # --- totals_line helpers ---             (altitude 3 — drops a level early)
  def total_gross = sales.sum(&:gross_revenue)
  def total_net   = sales.sum(&:net_revenue)

  # --- detailed_report parts ---           (back up to altitude 2)
  def detailed_header  = "=== Detailed Report ==="
  def per_region_table = sales_by_region.map { |r, g| region_row(r, g) }.join("\n")
  def detailed_footer  = "--- #{sales_by_region.size} regions ---"

  # --- per_region_table helpers ---        (altitude 3 again)
  def sales_by_region          = sales.group_by(&:region)
  def region_row(region, group) = format("%-12s %s", region, format_money(group.sum(&:gross_revenue)))

  # --- shared helpers ---                  (altitude 3, cross-cutting)
  def top_performers       = sales.group_by(&:performer).max_by(3) { |_, g| g.sum(&:gross_revenue) }.map(&:first)
  def format_money(amount) = format("$%.2f", amount)
end
```

Reordered **breadth-first by altitude**, the two public methods stay as they are and only the `private` section changes: every altitude-2 part clusters first, then every altitude-3 helper clusters below.

```ruby
  private

  attr_reader :sales

  # altitude 2 — the six report "parts", in report order
  def summary_header      = "=== Sales Summary ==="
  def totals_line         = "Totals: gross #{format_money(total_gross)}, net #{format_money(total_net)}"
  def top_performers_line = "Top: #{top_performers.join(', ')}"
  def detailed_header  = "=== Detailed Report ==="
  def per_region_table = sales_by_region.map { |r, g| region_row(r, g) }.join("\n")
  def detailed_footer  = "--- #{sales_by_region.size} regions ---"

  # altitude 3 — every helper those parts call (shared/leaf utilities sink last)
  def total_gross = sales.sum(&:gross_revenue)
  def total_net   = sales.sum(&:net_revenue)
  def sales_by_region          = sales.group_by(&:region)
  def region_row(region, group) = format("%-12s %s", region, format_money(group.sum(&:gross_revenue)))
  def top_performers       = sales.group_by(&:performer).max_by(3) { |_, g| g.sum(&:gross_revenue) }.map(&:first)
  def format_money(amount) = format("$%.2f", amount)
```

## Where shared helpers go

A helper called from more than one altitude has no single "home" level. Pick one convention and hold it:

- **Place it at the altitude of its highest (closest-to-public) caller.** Keeps it near the first place a reader meets it. Good when the helper is conceptually part of that higher step.
- **Collect all cross-cutting utilities in one labelled cluster at the very bottom** (formatting, money/date helpers, pure functions). Good when the helper is a generic tool with no natural owner — `format_money` is a classic case.

Whichever you choose, keep leaf utilities (`format_money`, `truncate`, `humanize`) *below* the domain helpers, since they are the lowest altitude in the file.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Helper defined immediately under its single caller | Group by altitude; put the next sibling step first, helpers below |
| Grouping by feature ("all summary methods, then all detail methods") | Group by altitude across features — all parts, then all helpers |
| Section comments that nest altitude-3 inside altitude-2 | A correct layout rarely needs them; let the altitude clusters speak |
| Public method buried between private helpers | All public methods come before `private`; entry points first |
| `attr_reader` for internal state above the public methods | Move internal-only readers just under `private` |
| Leaf utilities (`format_money`) near the top | Lowest-altitude helpers sink to the bottom |

## When the rule bends

- **A helper used by exactly one caller and meaningless without it** may sit directly under that caller — a tiny, tightly coupled pair reads fine depth-first.
- **Ruby/Rails macros** (`validates`, `scope`, `after_create`) always stay in the header block (step 3), regardless of altitude.
- **Generated or DSL-heavy files** (migrations, routes, config) follow their own framework order; this rule targets hand-written domain classes.

The test for any exception: does a newcomer still descend one abstraction level at a time as they read down? If yes, the layout is doing its job.
