# Visualizations

Three options. Pick by chart complexity:

| You need…                                                   | Use                       |
| ----------------------------------------------------------- | ------------------------- |
| A small bar/line, ≤ ~20 points, no axes needed              | inline **SVG** in a `figure` block |
| Anything with axes, multiple series, faceted, interactive   | **Vega-Lite** in a `chart` block |
| 3D / scientific / very large datasets                       | embed an iframe to an external tool (Plotly, Datasette, your dashboard) |

Don't introduce a new chart library per report. Stick to inline SVG
and Vega-Lite.

## Inline SVG sparkline

For a one-line trend indicator in the executive summary or in a table
cell. Author it directly; no library.

```jsonc
{
  "type": "figure",
  "id":   "fig-spark-rps",
  "caption": "RPS trend, last 24h",
  "svg": "<svg viewBox=\"0 0 200 40\" role=\"img\" aria-label=\"RPS trend, last 24h\"><polyline fill=\"none\" stroke=\"var(--accent)\" stroke-width=\"1.5\" points=\"0,30 20,28 40,29 60,22 80,18 100,14 120,12 140,10 160,8 180,6 200,5\"/></svg>"
}
```

Rules for hand-rolled SVG:

- Always set `role="img"` and a meaningful `aria-label`.
- Pull colors from CSS variables: `stroke="var(--accent)"`.
- Use `font-family="system-ui"` for any `<text>` inside the SVG.
- Don't include a background `<rect>` — let the page background show through.

## Vega-Lite: ground rules

The renderer auto-includes vega+vega-lite+vega-embed (from jsdelivr)
when any `chart` block is present. The spec is plain JSON, easy for
the agent to author, easy for a human to audit.

For every Vega-Lite spec:

- Set `"width": "container"` so it fits the column.
- Set an explicit `"height"` (220 is a sane default).
- Use `"$schema": "https://vega.github.io/schema/vega-lite/v5.json"`.
- Match the design palette via `"config": { "background": null }` so
  the chart inherits the page color.

## Recipe: line chart with multiple series

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data": { "values": [
    {"t": 0, "p50":  40, "p99": 120},
    {"t": 1, "p50":  42, "p99": 130},
    {"t": 2, "p50":  44, "p99": 480},
    {"t": 3, "p50":  41, "p99": 812}
  ]},
  "transform": [
    { "fold": ["p50", "p99"], "as": ["percentile", "ms"] }
  ],
  "mark": { "type": "line", "point": true },
  "encoding": {
    "x":     { "field": "t",    "type": "quantitative", "title": "minute" },
    "y":     { "field": "ms",   "type": "quantitative", "title": "latency (ms)" },
    "color": { "field": "percentile", "type": "nominal",
               "scale": { "range": ["#1F6FEB", "#CF222E"] } }
  },
  "width":  "container",
  "height": 240,
  "config": { "background": null, "view": { "stroke": null } }
}
```

## Recipe: bar chart with sorting

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data":   { "values": [
    {"endpoint": "/orders/write",     "p99": 812},
    {"endpoint": "/inventory",        "p99": 104},
    {"endpoint": "/users/me",         "p99":  62}
  ]},
  "mark": "bar",
  "encoding": {
    "x":     { "field": "p99",      "type": "quantitative", "title": "p99 (ms)" },
    "y":     { "field": "endpoint", "type": "nominal", "sort": "-x", "title": null },
    "color": { "value": "#1F6FEB" }
  },
  "width":  "container",
  "height": 200,
  "config": { "background": null, "view": { "stroke": null } }
}
```

## Recipe: faceted small multiples

For comparing the same metric across N entities (services, regions,
hosts). Set `"columns": 3` to get a 3-up grid.

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data": { "url": "data/per-service.json" },
  "facet": { "field": "service", "type": "nominal", "columns": 3, "title": null },
  "spec": {
    "mark": "line",
    "encoding": {
      "x": { "field": "t",   "type": "quantitative" },
      "y": { "field": "p99", "type": "quantitative" }
    },
    "width": 200, "height": 100
  },
  "config": { "background": null }
}
```

Note that the data lives in `data/per-service.json` (declared via
`dataFiles` in the spec). Big datasets stay out of the JSON spec.

## Recipe: scatter with tooltip

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data": { "values": [/* {x,y,label} ... */] },
  "mark": { "type": "point", "filled": true, "size": 60 },
  "encoding": {
    "x":     { "field": "x", "type": "quantitative" },
    "y":     { "field": "y", "type": "quantitative" },
    "color": { "value": "#1F6FEB" },
    "tooltip": [
      { "field": "label", "type": "nominal" },
      { "field": "x",     "type": "quantitative" },
      { "field": "y",     "type": "quantitative" }
    ]
  },
  "width":  "container",
  "height": 280,
  "config": { "background": null, "view": { "stroke": null } }
}
```

## Recipe: heatmap

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data": { "values": [/* {hour, day, count} ... */] },
  "mark": "rect",
  "encoding": {
    "x": { "field": "hour", "type": "ordinal", "title": "hour (UTC)" },
    "y": { "field": "day",  "type": "ordinal", "title": null },
    "color": {
      "field": "count", "type": "quantitative",
      "scale": { "scheme": "blues" }
    }
  },
  "width":  "container",
  "height": 160,
  "config": { "background": null, "view": { "stroke": null } }
}
```

## When to not use a chart

- Single data point → use a `kv` block with a big number and the unit.
- 2–4 data points → a `table` is often clearer than a chart.
- "Trending up" / "Trending down" without quantitative detail →
  use a sparkline SVG, not a chart with axes.

If the data is too small to need a chart, don't make one. Tables and
inline numbers communicate density better at low N.
