# songR Interactive Explorer
# Launched via songR::run_songR_app()

# ── CSS ──────────────────────────────────────────────────────────────────────
app_css <- "
/* ── Reset & base ── */
* { box-sizing: border-box; }
body {
  font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
  background: #f7f8fa;
  color: #1a1a2e;
  margin: 0;
}

/* ── Top navbar ── */
.navbar-songr {
  background: #ffffff;
  border-bottom: 1px solid #e2e5ea;
  padding: 0 32px;
  display: flex;
  align-items: center;
  height: 60px;
  position: sticky;
  top: 0;
  z-index: 999;
  box-shadow: 0 1px 4px rgba(0,0,0,.06);
}
.navbar-brand-songr {
  font-size: 1.25rem;
  font-weight: 700;
  color: #2563eb;
  letter-spacing: -0.3px;
  margin-right: 40px;
  text-decoration: none;
}
.navbar-brand-songr span { color: #6b7280; font-weight: 400; }
.nav-tabs-songr {
  display: flex;
  gap: 4px;
  list-style: none;
  margin: 0;
  padding: 0;
  height: 100%;
  align-items: stretch;
}
.nav-tabs-songr li a {
  display: flex;
  align-items: center;
  padding: 0 16px;
  height: 60px;
  font-size: 0.88rem;
  font-weight: 500;
  color: #6b7280;
  text-decoration: none;
  border-bottom: 2px solid transparent;
  transition: color .15s, border-color .15s;
  cursor: pointer;
}
.nav-tabs-songr li a:hover { color: #2563eb; }
.nav-tabs-songr li.active a { color: #2563eb; border-bottom-color: #2563eb; }

/* ── Page container ── */
.page-container { padding: 32px; max-width: 1400px; margin: 0 auto; }

/* ── Cards ── */
.card {
  background: #ffffff;
  border: 1px solid #e2e5ea;
  border-radius: 10px;
  padding: 28px 32px;
  margin-bottom: 24px;
}
.card-sm { padding: 20px 24px; }
.card-title {
  font-size: 1.05rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 16px 0;
}
.card-subtitle {
  font-size: 0.82rem;
  color: #6b7280;
  margin: -12px 0 16px 0;
}

/* ── Hero banner ── */
.hero {
  background: linear-gradient(135deg, #1e40af 0%, #2563eb 50%, #3b82f6 100%);
  color: white;
  border-radius: 14px;
  padding: 48px 52px;
  margin-bottom: 28px;
  position: relative;
  overflow: hidden;
}
.hero::after {
  content: '';
  position: absolute;
  right: -60px; top: -60px;
  width: 280px; height: 280px;
  background: rgba(255,255,255,.06);
  border-radius: 50%;
}
.hero h1 {
  font-size: 2.1rem;
  font-weight: 700;
  margin: 0 0 10px 0;
  letter-spacing: -0.5px;
}
.hero p {
  font-size: 1.05rem;
  opacity: .88;
  margin: 0 0 24px 0;
  max-width: 640px;
  line-height: 1.65;
}
.hero-badge {
  display: inline-block;
  background: rgba(255,255,255,.18);
  border: 1px solid rgba(255,255,255,.3);
  border-radius: 20px;
  padding: 4px 14px;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: .4px;
  margin-right: 8px;
  margin-bottom: 8px;
}

/* ── Feature grid ── */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 18px;
  margin-bottom: 28px;
}
.feature-card {
  background: #ffffff;
  border: 1px solid #e2e5ea;
  border-radius: 10px;
  padding: 24px;
  transition: box-shadow .15s;
}
.feature-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.08); }
.feature-icon {
  width: 40px; height: 40px;
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  font-size: 1.2rem;
  margin-bottom: 14px;
}
.icon-blue  { background: #eff6ff; }
.icon-green { background: #f0fdf4; }
.icon-amber { background: #fffbeb; }
.icon-purple { background: #faf5ff; }
.feature-card h3 {
  font-size: 0.95rem;
  font-weight: 600;
  margin: 0 0 8px 0;
  color: #111827;
}
.feature-card p {
  font-size: 0.85rem;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

/* ── Comparison table ── */
.compare-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.87rem;
}
.compare-table th {
  background: #f1f5f9;
  padding: 12px 18px;
  text-align: left;
  font-weight: 600;
  font-size: 0.83rem;
  color: #374151;
  border-bottom: 1px solid #e2e5ea;
}
.compare-table th:first-child { border-radius: 8px 0 0 0; }
.compare-table th:last-child  { border-radius: 0 8px 0 0; }
.compare-table td {
  padding: 11px 18px;
  border-bottom: 1px solid #f1f5f9;
  color: #374151;
  vertical-align: top;
}
.compare-table tr:last-child td { border-bottom: none; }
.compare-table .col-song { background: #f0f9ff; font-weight: 500; color: #1e40af; }
.badge-yes  { color: #16a34a; font-weight: 600; }
.badge-no   { color: #dc2626; font-weight: 600; }
.badge-part { color: #d97706; font-weight: 600; }

/* ── Citation block ── */
.citation-box {
  background: #f8fafc;
  border: 1px solid #e2e5ea;
  border-left: 4px solid #2563eb;
  border-radius: 0 8px 8px 0;
  padding: 18px 22px;
  font-family: 'Courier New', Courier, monospace;
  font-size: 0.82rem;
  line-height: 1.7;
  color: #374151;
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
}

/* ── Author cards ── */
.author-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
  gap: 14px;
  margin-top: 8px;
}
.author-card {
  background: #f8fafc;
  border: 1px solid #e2e5ea;
  border-radius: 8px;
  padding: 16px 18px;
}
.author-name { font-weight: 600; font-size: 0.9rem; color: #111827; margin-bottom: 2px; }
.author-role { font-size: 0.78rem; color: #6b7280; }
.author-aff  { font-size: 0.78rem; color: #9ca3af; margin-top: 2px; }

/* ── Algorithm steps ── */
.algo-steps { counter-reset: step; }
.algo-step {
  display: flex;
  gap: 18px;
  margin-bottom: 20px;
}
.algo-step-num {
  counter-increment: step;
  flex-shrink: 0;
  width: 34px; height: 34px;
  background: #2563eb;
  color: white;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700;
  font-size: 0.88rem;
}
.algo-step-body h4 {
  font-size: 0.92rem;
  font-weight: 600;
  margin: 6px 0 5px 0;
  color: #111827;
}
.algo-step-body p {
  font-size: 0.84rem;
  color: #6b7280;
  margin: 0;
  line-height: 1.6;
}

/* ── Sidebar (Compare page) ── */
.sidebar {
  background: #ffffff;
  border: 1px solid #e2e5ea;
  border-radius: 10px;
  padding: 22px 22px;
}
.sidebar h5 {
  font-size: 0.8rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .6px;
  color: #9ca3af;
  margin: 0 0 12px 0;
}
.sidebar-divider {
  border: none;
  border-top: 1px solid #f1f5f9;
  margin: 18px 0;
}

/* ── Run button ── */
.run-btn-wrap { margin-top: 6px; }
.btn-run {
  width: 100%;
  background: #2563eb;
  color: white !important;
  border: none;
  border-radius: 8px;
  padding: 10px 0;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: background .15s;
}
.btn-run:hover { background: #1d4ed8 !important; }

/* ── Timing pills ── */
.timing-row {
  display: flex; gap: 8px; flex-wrap: wrap; margin-top: 14px;
}
.timing-pill {
  display: flex; flex-direction: column;
  background: #f1f5f9;
  border-radius: 8px;
  padding: 8px 14px;
  flex: 1; min-width: 60px;
}
.timing-pill .t-label { font-size: 0.7rem; font-weight: 600; color: #9ca3af; letter-spacing: .4px; }
.timing-pill .t-value { font-size: 0.95rem; font-weight: 700; color: #111827; margin-top: 2px; }
.timing-pill.t-song .t-label { color: #2563eb; }

/* ── Plot area ── */
.plot-panel {
  background: #ffffff;
  border: 1px solid #e2e5ea;
  border-radius: 10px;
  padding: 18px;
}
.plot-label {
  font-size: 0.78rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .5px;
  color: #9ca3af;
  margin-bottom: 10px;
}

/* ── Shiny overrides ── */
.shiny-input-container { margin-bottom: 14px; }
.shiny-input-container label {
  font-size: 0.83rem;
  font-weight: 600;
  color: #374151;
  margin-bottom: 5px;
}
.form-control, .selectize-input {
  border: 1px solid #d1d5db !important;
  border-radius: 7px !important;
  font-size: 0.85rem !important;
}
.irs--shiny .irs-bar { background: #2563eb; border-top-color: #2563eb; border-bottom-color: #2563eb; }
.irs--shiny .irs-handle { border-color: #2563eb; }
.irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single { background: #2563eb; }

/* ── Verbatim output ── */
pre.shiny-text-output {
  background: #f8fafc;
  border: 1px solid #e2e5ea;
  border-radius: 8px;
  font-size: 0.82rem;
  padding: 16px 18px;
  color: #374151;
}

/* ── Section headings ── */
.section-title {
  font-size: 1.35rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 6px 0;
}
.section-lead {
  font-size: 0.95rem;
  color: #6b7280;
  line-height: 1.65;
  margin: 0 0 28px 0;
  max-width: 720px;
}

/* ── Info callout ── */
.callout {
  border-radius: 8px;
  padding: 14px 18px;
  font-size: 0.85rem;
  line-height: 1.6;
  margin-bottom: 20px;
}
.callout-blue { background: #eff6ff; border-left: 3px solid #2563eb; color: #1e3a8a; }
.callout-green { background: #f0fdf4; border-left: 3px solid #16a34a; color: #14532d; }

/* ── Dark mode toggle ── */
.dark-toggle {
  margin-left: auto;
  background: none;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  color: #6b7280;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all .15s;
}
.dark-toggle:hover { border-color: #2563eb; color: #2563eb; }

/* ── Dark mode theme ── */
body.dark-mode { background: #0f1117; color: #e2e5ea; }
body.dark-mode .navbar-songr {
  background: #1a1d28; border-bottom-color: #2a2d3a;
  box-shadow: 0 1px 4px rgba(0,0,0,.3);
}
body.dark-mode .navbar-brand-songr { color: #818cf8; }
body.dark-mode .navbar-brand-songr span { color: #9ca3af; }
body.dark-mode .nav-tabs-songr li a { color: #9ca3af; }
body.dark-mode .nav-tabs-songr li a:hover { color: #818cf8; }
body.dark-mode .nav-tabs-songr li.active a { color: #818cf8; border-bottom-color: #818cf8; }
body.dark-mode .card, body.dark-mode .sidebar, body.dark-mode .plot-panel,
body.dark-mode .feature-card { background: #1a1d28; border-color: #2a2d3a; }
body.dark-mode .card-title, body.dark-mode .section-title,
body.dark-mode .feature-card h3, body.dark-mode .algo-step-body h4 { color: #f1f5f9; }
body.dark-mode .card-subtitle, body.dark-mode .section-lead,
body.dark-mode .feature-card p, body.dark-mode .algo-step-body p,
body.dark-mode .plot-label, body.dark-mode .sidebar h5 { color: #9ca3af; }
body.dark-mode .hero { background: linear-gradient(135deg, #312e81 0%, #4338ca 50%, #6366f1 100%); }
body.dark-mode .compare-table th { background: #1e2030; color: #d1d5db; border-color: #2a2d3a; }
body.dark-mode .compare-table td { border-color: #2a2d3a; color: #d1d5db; }
body.dark-mode .compare-table .col-song { background: #1e1b4b; color: #a5b4fc; }
body.dark-mode .timing-pill { background: #1e2030; }
body.dark-mode .timing-pill .t-value { color: #f1f5f9; }
body.dark-mode .form-control, body.dark-mode .selectize-input {
  background: #1e2030 !important; border-color: #374151 !important; color: #e2e5ea !important;
}
body.dark-mode .selectize-dropdown { background: #1e2030; border-color: #374151; color: #e2e5ea; }
body.dark-mode .selectize-dropdown-content .option { color: #e2e5ea; }
body.dark-mode .selectize-dropdown-content .active { background: #2a2d3a; }
body.dark-mode pre.shiny-text-output { background: #1e2030; border-color: #2a2d3a; color: #d1d5db; }
body.dark-mode .citation-box { background: #1e2030; border-color: #2a2d3a; color: #d1d5db; }
body.dark-mode .callout-blue { background: #1e1b4b; border-left-color: #818cf8; color: #c7d2fe; }
body.dark-mode .callout-green { background: #052e16; border-left-color: #22c55e; color: #bbf7d0; }
body.dark-mode .btn-run { background: #6366f1; }
body.dark-mode .btn-run:hover { background: #4f46e5 !important; }
body.dark-mode .dark-toggle { border-color: #374151; color: #9ca3af; }
body.dark-mode .dark-toggle:hover { border-color: #818cf8; color: #818cf8; }
body.dark-mode .sidebar-divider { border-top-color: #2a2d3a; }
body.dark-mode .irs--shiny .irs-bar { background: #818cf8; border-color: #818cf8; }
body.dark-mode .irs--shiny .irs-handle { border-color: #818cf8; }
body.dark-mode .irs--shiny .irs-from, body.dark-mode .irs--shiny .irs-to,
body.dark-mode .irs--shiny .irs-single { background: #818cf8; }
body.dark-mode .irs--shiny .irs-line { background: #2a2d3a; }
body.dark-mode .irs--shiny .irs-grid-text { color: #6b7280; }
body.dark-mode .shiny-input-container label { color: #d1d5db; }
body.dark-mode .author-card { background: #1e2030; border-color: #2a2d3a; }
body.dark-mode .author-name { color: #f1f5f9; }
body.dark-mode .feature-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.3); }
"

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- shiny::tagList(
  shiny::tags$head(
    shiny::tags$style(shiny::HTML(app_css)),
    shiny::tags$title("songR Explorer")
  ),

  # Top navbar
  shiny::tags$nav(class = "navbar-songr",
    shiny::tags$span(class = "navbar-brand-songr",
      "songR ", shiny::tags$span("Explorer")),
    shiny::tags$ul(class = "nav-tabs-songr", id = "main-nav",
      shiny::tags$li(class = "active", id = "nav-about",
        shiny::tags$a(onclick = "showPage('about')", "About")),
      shiny::tags$li(id = "nav-compare",
        shiny::tags$a(onclick = "showPage('compare')", "Compare")),
      shiny::tags$li(id = "nav-details",
        shiny::tags$a(onclick = "showPage('details')", "SONG Details")),
      shiny::tags$li(id = "nav-algorithm",
        shiny::tags$a(onclick = "showPage('algorithm')", "Algorithm"))
    ),
    shiny::tags$button(class = "dark-toggle", id = "dark-toggle-btn",
                       onclick = "toggleDarkMode()",
                       shiny::HTML("&#9790; Dark Mode"))
  ),

  # JS page switcher + dark mode toggle
  shiny::tags$script(shiny::HTML("
    function showPage(page) {
      ['about','compare','details','algorithm'].forEach(function(p) {
        document.getElementById('page-' + p).style.display = (p === page) ? 'block' : 'none';
        var li = document.getElementById('nav-' + p);
        if (li) li.className = (p === page) ? 'active' : '';
      });
    }
    function toggleDarkMode() {
      document.body.classList.toggle('dark-mode');
      var btn = document.getElementById('dark-toggle-btn');
      var isDark = document.body.classList.contains('dark-mode');
      btn.innerHTML = isDark ? '&#9788; Light Mode' : '&#9790; Dark Mode';
      localStorage.setItem('songR_dark_mode', isDark ? '1' : '0');
      if (typeof Shiny !== 'undefined') Shiny.setInputValue('dark_mode', isDark);
    }
    document.addEventListener('DOMContentLoaded', function() {
      showPage('about');
      if (localStorage.getItem('songR_dark_mode') === '1') toggleDarkMode();
    });
  ")),

  # ── PAGE: ABOUT ────────────────────────────────────────────────────────────
  shiny::tags$div(id = "page-about", class = "page-container",

    # Hero
    shiny::tags$div(class = "hero",
      shiny::tags$h1("Self-Organizing Nebulous Growths"),
      shiny::tags$p(
        "SONG is a topology-preserving, incrementally updatable dimensionality ",
        "reduction algorithm — a powerful alternative to t-SNE and UMAP for ",
        "both batch and streaming high-dimensional data."
      ),
      shiny::tags$span(class = "hero-badge", "IEEE TNNLS 2021"),
      shiny::tags$span(class = "hero-badge", "Incremental"),
      shiny::tags$span(class = "hero-badge", "Native R/C++"),
      shiny::tags$span(class = "hero-badge", "Topology-Preserving")
    ),

    # Feature cards
    shiny::tags$div(class = "feature-grid",
      shiny::tags$div(class = "feature-card",
        shiny::tags$div(class = "feature-icon icon-blue", "\U0001F504"),
        shiny::tags$h3("Incremental Updates"),
        shiny::tags$p(
          "Add new data to an existing visualization without reinitialization. ",
          "t-SNE and UMAP require a full refit from scratch every time new data arrives."
        )
      ),
      shiny::tags$div(class = "feature-card",
        shiny::tags$div(class = "feature-icon icon-green", "\U0001F9E9"),
        shiny::tags$h3("Topology Preservation"),
        shiny::tags$p(
          "The growing neural graph captures the topological structure of the data ",
          "manifold, producing embeddings that faithfully reflect cluster boundaries."
        )
      ),
      shiny::tags$div(class = "feature-card",
        shiny::tags$div(class = "feature-icon icon-amber", "\U0001F4CA"),
        shiny::tags$h3("Adaptive Resolution"),
        shiny::tags$p(
          "The codebook grows automatically: sparse regions use fewer coding vectors, ",
          "dense regions grow more — resolution adapts to local data density."
        )
      ),
      shiny::tags$div(class = "feature-card",
        shiny::tags$div(class = "feature-icon icon-purple", "\U0001F6E1\uFE0F"),
        shiny::tags$h3("Noise Robustness"),
        shiny::tags$p(
          "The graph-based self-organization step is inherently more robust to noise ",
          "and outliers than kernel-based spectral methods such as t-SNE."
        )
      )
    ),

    # SONG vs t-SNE vs UMAP
    shiny::tags$div(class = "card",
      shiny::tags$h2(class = "section-title", "SONG vs t-SNE vs UMAP"),
      shiny::tags$p(class = "section-lead",
        "All three methods produce nonlinear 2-D embeddings of high-dimensional data. ",
        "They differ significantly in how they handle new data, scalability, and the ",
        "structural assumptions they make."
      ),
      shiny::tags$table(class = "compare-table",
        shiny::tags$thead(
          shiny::tags$tr(
            shiny::tags$th("Property"),
            shiny::tags$th("SONG"),
            shiny::tags$th("t-SNE"),
            shiny::tags$th("UMAP")
          )
        ),
        shiny::tags$tbody(
          shiny::tags$tr(
            shiny::tags$td("Incremental new-data updates"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 Yes")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No — full refit")),
            shiny::tags$td(shiny::tags$span(class = "badge-part", "\u25D0 Partial (parametric variant only)"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Scalable to large datasets"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 Yes")),
            shiny::tags$td(shiny::tags$span(class = "badge-part", "\u25D0 Partial (Barnes-Hut)")),
            shiny::tags$td(shiny::tags$span(class = "badge-yes", "\u2714 Yes"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Explicit topology graph"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 Yes — coding vector graph")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No")),
            shiny::tags$td(shiny::tags$span(class = "badge-part", "\u25D0 Fuzzy simplicial set (implicit)"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Handles heterogeneous data increments"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 Yes")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Adaptive codebook resolution"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 Yes — self-organizing growth")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No")),
            shiny::tags$td(shiny::tags$span(class = "badge-no", "\u2718 No"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Noise & outlier robustness"),
            shiny::tags$td(class = "col-song", shiny::tags$span(class = "badge-yes", "\u2714 High")),
            shiny::tags$td(shiny::tags$span(class = "badge-part", "\u25D0 Moderate")),
            shiny::tags$td(shiny::tags$span(class = "badge-part", "\u25D0 Moderate"))
          ),
          shiny::tags$tr(
            shiny::tags$td("Cluster separation"),
            shiny::tags$td(class = "col-song", "Sharp (graph topology drives separation)"),
            shiny::tags$td("Sharp (but unstable across runs)"),
            shiny::tags$td("Sharp (tunable via min_dist)")
          ),
          shiny::tags$tr(
            shiny::tags$td("Theoretical basis"),
            shiny::tags$td(class = "col-song", "Self-organizing maps + GSOM + UMAP repulsion"),
            shiny::tags$td("t-distribution + KL divergence"),
            shiny::tags$td("Riemannian geometry + fuzzy topology")
          )
        )
      )
    ),

    # When to use
    shiny::tags$div(class = "card",
      shiny::tags$h2(class = "section-title", "When to Use SONG"),
      shiny::tags$div(class = "callout callout-blue",
        shiny::tags$strong("Best fit for SONG: "),
        "streaming or growing datasets where new batches arrive over time; ",
        "longitudinal studies; single-cell RNA-seq atlases that are updated with new samples; ",
        "any workflow where a full t-SNE/UMAP refit on the combined data is computationally ",
        "prohibitive or destroys alignment with previous visualizations."
      ),
      shiny::tags$div(class = "callout callout-green",
        shiny::tags$strong("Also consider SONG when: "),
        "you need an explicit topology graph (e.g., for cluster boundary analysis); ",
        "you want the embedding to reflect the density structure of the data; ",
        "or you need noise robustness that is built into the algorithm rather than ",
        "dependent on preprocessing."
      )
    ),

    # Authors & citation
    shiny::tags$div(class = "card",
      shiny::tags$h2(class = "section-title", "Original Algorithm — Authors & Citation"),
      shiny::tags$p(style = "color:#6b7280;font-size:.9rem;margin:0 0 20px 0;",
        "The SONG algorithm was introduced in the following peer-reviewed article. ",
        "This R package is a native C++ port of their work. Please cite the original paper ",
        "when using songR in your research."
      ),
      shiny::tags$div(class = "author-grid",
        shiny::tags$div(class = "author-card",
          shiny::tags$div(class = "author-name", "Damith A. Senanayake"),
          shiny::tags$div(class = "author-role", "Lead Author"),
          shiny::tags$div(class = "author-aff", "University of Melbourne")
        ),
        shiny::tags$div(class = "author-card",
          shiny::tags$div(class = "author-name", "Wei Wang"),
          shiny::tags$div(class = "author-role", "Co-Author"),
          shiny::tags$div(class = "author-aff", "University of Melbourne")
        ),
        shiny::tags$div(class = "author-card",
          shiny::tags$div(class = "author-name", "Shalin H. Naik"),
          shiny::tags$div(class = "author-role", "Co-Author"),
          shiny::tags$div(class = "author-aff", "Walter and Eliza Hall Institute")
        ),
        shiny::tags$div(class = "author-card",
          shiny::tags$div(class = "author-name", "Saman K. Halgamuge"),
          shiny::tags$div(class = "author-role", "Senior Author"),
          shiny::tags$div(class = "author-aff", "University of Melbourne")
        )
      ),
      shiny::tags$br(),
      shiny::tags$div(class = "citation-box",
"Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data Visualization.
IEEE Transactions on Neural Networks and Learning Systems, 32(10), 4588-4602.
DOI: 10.1109/TNNLS.2020.3023941"
      )
    ),

    # R package authors
    shiny::tags$div(class = "card",
      shiny::tags$h2(class = "section-title", "This R Package"),
      shiny::tags$p(style = "color:#6b7280;font-size:.9rem;margin:0 0 20px 0;",
        "songR is a native R/C++ implementation built with Rcpp and RcppArmadillo. ",
        "No Python or reticulate dependency required."
      ),
      shiny::tags$div(class = "author-grid",
        shiny::tags$div(class = "author-card",
          shiny::tags$div(class = "author-name", "Raban Heller"),
          shiny::tags$div(class = "author-role", "Author, Maintainer"),
          shiny::tags$div(class = "author-aff",
            "University of Ulm",
            shiny::tags$br(),
            shiny::tags$span(style = "color:#9ca3af;",
              "ORCID: 0000-0001-8006-9742"))
        )
      )
    )
  ), # end page-about

  # ── PAGE: COMPARE ──────────────────────────────────────────────────────────
  shiny::tags$div(id = "page-compare", class = "page-container",
    style = "display:none;",

    shiny::tags$h1(class = "section-title", "Side-by-Side Comparison"),
    shiny::tags$p(class = "section-lead",
      "Run SONG, t-SNE, and UMAP on the same dataset and compare the resulting 2-D embeddings."),

    shiny::fluidRow(
      # Sidebar
      shiny::column(3,
        shiny::tags$div(class = "sidebar",

          shiny::tags$h5("Dataset"),
          shiny::selectInput("dataset", NULL,
            choices = c("Iris" = "iris",
                        "Gaussian Blobs (8 clusters, 20D)" = "blobs",
                        "Upload CSV" = "upload"),
            width = "100%"),
          shiny::conditionalPanel(
            condition = "input.dataset == 'upload'",
            shiny::fileInput("csv_file", "CSV file", accept = ".csv", width = "100%"),
            shiny::uiOutput("col_selector_ui"),
            shiny::uiOutput("label_selector_ui")
          ),

          shiny::tags$hr(class = "sidebar-divider"),
          shiny::tags$h5("SONG"),
          shiny::numericInput("song_k", "k (neighborhood)", value = 3, min = 3, max = 20, width = "100%"),
          shiny::sliderInput("song_sf", "spread_factor", min = 0.01, max = 0.99,
                             value = 0.5, step = 0.01, width = "100%"),
          shiny::numericInput("song_epochs", "epochs", value = 50, min = 5, max = 500, width = "100%"),
          shiny::numericInput("song_epsilon", "epsilon (edge decay)", value = 0.9,
                              min = 0.5, max = 0.999, step = 0.01, width = "100%"),
          shiny::checkboxInput("song_dispersion", "UMAP dispersion step", value = TRUE),

          shiny::tags$hr(class = "sidebar-divider"),
          shiny::tags$h5("t-SNE"),
          shiny::numericInput("tsne_perp", "perplexity", value = 30, min = 5, max = 100, width = "100%"),

          shiny::tags$hr(class = "sidebar-divider"),
          shiny::tags$h5("UMAP"),
          shiny::numericInput("umap_nn", "n_neighbors", value = 15, min = 2, max = 100, width = "100%"),

          shiny::tags$hr(class = "sidebar-divider"),
          shiny::tags$h5("General"),
          shiny::numericInput("seed", "Random seed", value = 42, width = "100%"),

          shiny::tags$div(class = "run-btn-wrap",
            shiny::actionButton("run_btn", "Run Comparison",
                                class = "btn-run", width = "100%")
          ),

          shiny::uiOutput("timing_ui")
        )
      ),

      # Plots
      shiny::column(9,
        shiny::fluidRow(
          shiny::column(4,
            shiny::tags$div(class = "plot-panel",
              shiny::tags$div(class = "plot-label", "SONG"),
              shiny::plotOutput("song_plot", height = "430px")
            )
          ),
          shiny::column(4,
            shiny::tags$div(class = "plot-panel",
              shiny::tags$div(class = "plot-label", "t-SNE"),
              shiny::plotOutput("tsne_plot", height = "430px")
            )
          ),
          shiny::column(4,
            shiny::tags$div(class = "plot-panel",
              shiny::tags$div(class = "plot-label", "UMAP"),
              shiny::plotOutput("umap_plot", height = "430px")
            )
          )
        )
      )
    )
  ), # end page-compare

  # ── PAGE: SONG DETAILS ─────────────────────────────────────────────────────
  shiny::tags$div(id = "page-details", class = "page-container",
    style = "display:none;",

    shiny::tags$h1(class = "section-title", "SONG Model Details"),
    shiny::tags$p(class = "section-lead",
      "Inspect the learned coding vector topology and model diagnostics."),

    shiny::uiOutput("details_content_ui")

  ), # end page-details

  # ── PAGE: ALGORITHM ────────────────────────────────────────────────────────
  shiny::tags$div(id = "page-algorithm", class = "page-container",
    style = "display:none;",

    shiny::tags$h1(class = "section-title", "The SONG Algorithm"),
    shiny::tags$p(class = "section-lead",
      "SONG trains via four interleaved steps applied to each input sample. ",
      "The algorithm combines ideas from Growing Self-Organizing Maps (GSOM), ",
      "Neural Gas, and UMAP's cross-entropy repulsion."),

    shiny::fluidRow(
      shiny::column(7,
        shiny::tags$div(class = "card",
          shiny::tags$div(class = "card-title", "Training Loop — Per Sample"),
          shiny::tags$div(class = "algo-steps",
            shiny::tags$div(class = "algo-step",
              shiny::tags$div(class = "algo-step-num", "1"),
              shiny::tags$div(class = "algo-step-body",
                shiny::tags$h4("Edge Curation"),
                shiny::tags$p(
                  "Find the k nearest coding vectors (CVs) to the input sample. ",
                  "Decay all outgoing edges of the best-matching unit (BMU) by ",
                  "factor \u03B5, then unconditionally reset the k-nearest edges to ",
                  "strength 1. Edges that fall below a minimum threshold are pruned, ",
                  "keeping the graph sparse and up-to-date."
                )
              )
            ),
            shiny::tags$div(class = "algo-step",
              shiny::tags$div(class = "algo-step-num", "2"),
              shiny::tags$div(class = "algo-step-body",
                shiny::tags$h4("Self-Organization of Coding Vectors"),
                shiny::tags$p(
                  "Move the BMU toward the input sample with learning rate \u03B1. ",
                  "Move each graph neighbor of the BMU by an exponentially decaying ",
                  "fraction of the same correction (Gaussian neighborhood function). ",
                  "This ensures the CV lattice reflects the local geometry of the data."
                )
              )
            ),
            shiny::tags$div(class = "algo-step",
              shiny::tags$div(class = "algo-step-num", "3"),
              shiny::tags$div(class = "algo-step-body",
                shiny::tags$h4("Topology Preservation of Embedding Y"),
                shiny::tags$p(
                  "Attract connected CVs in the 2-D embedding space using a rational ",
                  "quadratic kernel (identical to UMAP\u2019s attraction term). ",
                  "Repel a sample of non-adjacent CVs using UMAP\u2019s repulsion gradient. ",
                  "Both attraction and repulsion are symmetric mutual updates with ",
                  "gradient clipping to \u00B14 for numerical stability."
                )
              )
            ),
            shiny::tags$div(class = "algo-step",
              shiny::tags$div(class = "algo-step-num", "4"),
              shiny::tags$div(class = "algo-step-body",
                shiny::tags$h4("Growth"),
                shiny::tags$p(
                  "Accumulate the squared quantization error for each BMU. When it ",
                  "exceeds the threshold \u03B8 = \u2212ln(D)\u00B7ln(spread_factor), a new CV is ",
                  "inserted at 90% of the BMU\u2019s position + 10% toward the neighbor mean ",
                  "(matching the Python reference). The new CV\u2019s embedding coordinate ",
                  "is placed almost exactly at the BMU\u2019s Y position. ",
                  "The error accumulator is reset after each growth event."
                )
              )
            )
          )
        ),

        shiny::tags$div(class = "card",
          shiny::tags$div(class = "card-title", "Key Hyperparameters"),
          shiny::tags$table(class = "compare-table",
            shiny::tags$thead(
              shiny::tags$tr(
                shiny::tags$th("Parameter"),
                shiny::tags$th("Default"),
                shiny::tags$th("Effect")
              )
            ),
            shiny::tags$tbody(
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("spread_factor")),
                shiny::tags$td("0.5"),
                shiny::tags$td("Controls growth threshold \u03B8 = \u2212ln(D)\u00B7ln(sf). Higher sf \u2192 lower \u03B8 \u2192 more CVs, finer resolution. Lower sf \u2192 fewer CVs.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("k")),
                shiny::tags$td("3"),
                shiny::tags$td("Neighborhood size for the coding-vector graph. Must be at least d + 1 (3 for a 2-D embedding). Higher k = denser graph, more noise tolerance.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("epsilon")),
                shiny::tags$td("0.9"),
                shiny::tags$td("Edge decay rate. Edges weaker than epsilon^(d+max_age) are pruned. Lower = sparser, faster-pruning graph = better separation.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("max_age")),
                shiny::tags$td("3"),
                shiny::tags$td("Edge pruning threshold exponent. e_min = epsilon^(d+max_age). Higher = more aggressive pruning.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("neg_sample_rate")),
                shiny::tags$td("5"),
                shiny::tags$td("Repulsion samples per positive edge. Higher = stronger cluster separation in embedding.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("dispersion")),
                shiny::tags$td("TRUE"),
                shiny::tags$td("Run UMAP refinement initialized from SONG\u2019s Y. Matches Python\u2019s transform() step. Dramatically improves visual cluster separation.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("alpha")),
                shiny::tags$td("1.0"),
                shiny::tags$td("Initial learning rate, linearly decayed to 0 over training.")
              ),
              shiny::tags$tr(
                shiny::tags$td(shiny::tags$code("epochs")),
                shiny::tags$td("50"),
                shiny::tags$td("Number of SONG self-organization passes over the data. More passes = better convergence, slower.")
              )
            )
          )
        )
      ),

      shiny::column(5,
        shiny::tags$div(class = "card",
          shiny::tags$div(class = "card-title", "Relationship to Other Methods"),
          shiny::tags$p(style = "font-size:.85rem;color:#374151;line-height:1.7;margin:0 0 14px 0;",
            "SONG synthesizes three established ideas into a single coherent algorithm:"
          ),
          shiny::tags$div(style = "font-size:.84rem;line-height:1.75;color:#374151;",
            shiny::tags$p(
              shiny::tags$strong("Growing Self-Organizing Map (GSOM): "),
              "The growth mechanism and spread-factor threshold \u03B8\u1D4D originate from ",
              "Alahakoon et al. (2000). SONG extends this to the embedding space."
            ),
            shiny::tags$p(
              shiny::tags$strong("Neural Gas: "),
              "The exponentially-weighted neighborhood update in Step 2 is analogous to ",
              "Martinetz & Schulten\u2019s Neural Gas, but uses the learned graph topology ",
              "rather than a global ranking of distances."
            ),
            shiny::tags$p(
              shiny::tags$strong("UMAP: "),
              "The attraction and repulsion kernels in Step 3 are taken directly from ",
              "McInnes et al.\u2019s UMAP (cross-entropy optimization on a fuzzy graph). ",
              "SONG replaces UMAP\u2019s spectral initialization with the self-organized ",
              "graph, giving it incremental update capability."
            )
          )
        ),

        shiny::tags$div(class = "card",
          shiny::tags$div(class = "card-title", "References"),
          shiny::tags$div(style = "font-size:.82rem;line-height:1.75;color:#374151;",
            shiny::tags$p(
              shiny::tags$strong("Primary: "),
              "Senanayake, D.A., Wang, W., Naik, S.H., & Halgamuge, S. (2021). ",
              "Self-Organizing Nebulous Growths for Robust and Incremental Data ",
              "Visualization. ", shiny::tags$em("IEEE TNNLS"), ", 32(10), 4588\u20134602. ",
              shiny::tags$a(href = "https://doi.org/10.1109/TNNLS.2020.3023941",
                            "doi:10.1109/TNNLS.2020.3023941", target = "_blank")
            ),
            shiny::tags$p(
              shiny::tags$strong("GSOM: "),
              "Alahakoon, D., Halgamuge, S.K., & Srinivasan, B. (2000). ",
              "Dynamic Self-Organizing Maps with Controlled Growth. ",
              shiny::tags$em("IEEE TNN"), ", 11(3), 601\u2013614."
            ),
            shiny::tags$p(
              shiny::tags$strong("UMAP: "),
              "McInnes, L., Healy, J., & Melville, J. (2018). ",
              "UMAP: Uniform Manifold Approximation and Projection. ",
              shiny::tags$em("arXiv:1802.03426.")
            ),
            shiny::tags$p(
              shiny::tags$strong("t-SNE: "),
              "van der Maaten, L. & Hinton, G. (2008). ",
              "Visualizing Data using t-SNE. ",
              shiny::tags$em("JMLR"), ", 9, 2579\u20132605."
            )
          )
        )
      )
    )
  ) # end page-algorithm
)

# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  data_reactive <- shiny::reactive({
    if (input$dataset == "iris") {
      list(data = as.matrix(iris[, 1:4]), labels = iris$Species)
    } else if (input$dataset == "blobs") {
      data("songR_blobs", package = "songR", envir = environment())
      list(data = songR_blobs$data, labels = songR_blobs$labels)
    } else if (input$dataset == "upload" && !is.null(input$csv_file)) {
      df <- utils::read.csv(input$csv_file$datapath)
      list(full_df = df)
    } else {
      NULL
    }
  })

  output$col_selector_ui <- shiny::renderUI({
    d <- data_reactive()
    if (!is.null(d$full_df)) {
      num_cols <- names(d$full_df)[vapply(d$full_df, is.numeric, logical(1))]
      shiny::selectInput("feature_cols", "Feature columns", choices = num_cols,
                         selected = num_cols, multiple = TRUE, width = "100%")
    }
  })

  output$label_selector_ui <- shiny::renderUI({
    d <- data_reactive()
    if (!is.null(d$full_df)) {
      shiny::selectInput("label_col", "Label column (optional)",
                         choices = c("(none)" = "", names(d$full_df)), width = "100%")
    }
  })

  results <- shiny::reactiveValues(
    song_model = NULL, tsne_result = NULL, umap_result = NULL,
    song_time = NA, tsne_time = NA, umap_time = NA,
    data = NULL, labels = NULL
  )

  shiny::observeEvent(input$run_btn, {
    d <- data_reactive()
    if (is.null(d)) return()

    if (!is.null(d$data)) {
      mat    <- d$data
      labels <- d$labels
    } else if (!is.null(d$full_df)) {
      shiny::req(input$feature_cols)
      mat    <- as.matrix(d$full_df[, input$feature_cols, drop = FALSE])
      labels <- if (!is.null(input$label_col) && input$label_col != "") {
        as.factor(d$full_df[[input$label_col]])
      } else {
        NULL
      }
    } else {
      return()
    }

    results$data   <- mat
    results$labels <- labels

    shiny::withProgress(message = "Running comparisons\u2026", value = 0, {

      shiny::setProgress(0.1, detail = "Running SONG\u2026")
      t_song <- system.time({
        results$song_model <- tryCatch(
          songR::song(mat, k = input$song_k, spread_factor = input$song_sf,
                      epsilon = input$song_epsilon,
                      epochs = as.integer(input$song_epochs), seed = as.integer(input$seed),
                      dispersion = isTRUE(input$song_dispersion),
                      verbose = FALSE),
          error = function(e) {
            shiny::showNotification(paste("SONG error:", e$message), type = "error")
            NULL
          }
        )
      })
      results$song_time <- t_song["elapsed"]

      shiny::setProgress(0.4, detail = "Running t-SNE\u2026")
      t_tsne <- system.time({
        results$tsne_result <- tryCatch({
          perp <- min(input$tsne_perp, floor((nrow(mat) - 1) / 3))
          Rtsne::Rtsne(mat, dims = 2, perplexity = perp,
                       verbose = FALSE, check_duplicates = FALSE)$Y
        }, error = function(e) {
          shiny::showNotification(paste("t-SNE error:", e$message), type = "error")
          NULL
        })
      })
      results$tsne_time <- t_tsne["elapsed"]

      shiny::setProgress(0.7, detail = "Running UMAP\u2026")
      t_umap <- system.time({
        results$umap_result <- tryCatch(
          uwot::umap(mat, n_neighbors = input$umap_nn, n_components = 2, verbose = FALSE),
          error = function(e) {
            shiny::showNotification(paste("UMAP error:", e$message), type = "error")
            NULL
          }
        )
      })
      results$umap_time <- t_umap["elapsed"]

      shiny::setProgress(1, detail = "Done!")
    })
  })

  # ── Plot helper ──────────────────────────────────────────────────────────
  make_embed_plot <- function(coords, labels, title, dark = FALSE) {
    bg_col  <- if (dark) "#1a1d28" else "#ffffff"
    txt_col <- if (dark) "#e2e5ea" else "#1a1a2e"
    box_col <- if (dark) "#2a2d3a" else "#e2e5ea"

    if (is.null(coords)) {
      graphics::par(bg = bg_col)
      graphics::plot.new()
      graphics::text(0.5, 0.5, paste(title, "\u2014 not available"),
                     adj = c(0.5, 0.5), col = "#9ca3af", cex = 1.1)
      return(invisible(NULL))
    }
    graphics::par(bg = bg_col, mar = c(2, 2, 1.5, 1), fg = txt_col,
                  col.axis = txt_col, col.lab = txt_col, col.main = txt_col)

    if (!is.null(labels)) {
      lvls    <- levels(as.factor(labels))
      n_lvls  <- length(lvls)
      palette <- viridis::plasma(n_lvls, end = 0.92)
      col     <- palette[as.integer(as.factor(labels))]
    } else {
      col     <- "#B12A90"
      lvls    <- NULL
      palette <- NULL
    }

    graphics::plot(coords[, 1], coords[, 2], col = col,
                   pch = 16, cex = 0.65, axes = FALSE,
                   xlab = "", ylab = "", main = "")
    graphics::box(col = box_col)
    if (!is.null(lvls) && n_lvls <= 20) {
      graphics::legend("topright", legend = lvls, col = palette, pch = 16,
                       cex = 0.7, bty = "n", pt.cex = 0.9,
                       text.col = txt_col)
    }
  }

  plot_bg <- shiny::reactive({
    if (isTRUE(input$dark_mode)) "#1a1d28" else "white"
  })

  output$song_plot <- shiny::renderPlot({
    shiny::req(results$song_model)
    make_embed_plot(results$song_model$embedding, results$labels, "SONG",
                    dark = isTRUE(input$dark_mode))
  }, bg = shiny::reactive({ plot_bg() }))

  output$tsne_plot <- shiny::renderPlot({
    shiny::req(results$tsne_result)
    make_embed_plot(results$tsne_result, results$labels, "t-SNE",
                    dark = isTRUE(input$dark_mode))
  }, bg = shiny::reactive({ plot_bg() }))

  output$umap_plot <- shiny::renderPlot({
    shiny::req(results$umap_result)
    make_embed_plot(results$umap_result, results$labels, "UMAP",
                    dark = isTRUE(input$dark_mode))
  }, bg = shiny::reactive({ plot_bg() }))

  output$details_content_ui <- shiny::renderUI({
    if (is.null(results$song_model)) {
      shiny::tags$div(class = "card",
        style = "text-align:center; padding:60px 32px; color:#6b7280;",
        shiny::tags$div(style = "font-size:2.5rem; margin-bottom:12px;", "\U0001f50d"),
        shiny::tags$p(style = "font-size:1.05rem; font-weight:500; margin:0 0 8px 0;",
          "No model to inspect yet"),
        shiny::tags$p(style = "font-size:.88rem; margin:0;",
          "Run a comparison on the ", shiny::tags$strong("Compare"),
          " tab first, then come back here to explore the SONG codebook graph ",
          "and model diagnostics.")
      )
    } else {
      shiny::tagList(
        shiny::fluidRow(
          shiny::column(7,
            shiny::tags$div(class = "card", style = "padding:18px;",
              shiny::tags$div(class = "card-title", "Coding Vector Graph"),
              shiny::tags$div(class = "card-subtitle",
                "Nodes = coding vectors, edges = learned topology"),
              shiny::plotOutput("song_graph_plot", height = "520px")
            )
          ),
          shiny::column(5,
            shiny::tags$div(class = "card",
              shiny::tags$div(class = "card-title", "Model Summary"),
              shiny::verbatimTextOutput("song_summary")
            ),
            shiny::tags$div(class = "card",
              shiny::tags$div(class = "card-title", "What do these numbers mean?"),
              shiny::tags$p(style = "font-size:.84rem;color:#6b7280;line-height:1.7;margin:0;",
                shiny::tags$strong("Coding vectors (CVs): "),
                "Prototype points that discretize the data manifold. Each input point is ",
                "assigned to its nearest CV.",
                shiny::tags$br(), shiny::tags$br(),
                shiny::tags$strong("Edges: "),
                "Connections between CVs whose neighborhoods overlap. The edge structure ",
                "encodes the topological skeleton of the data.",
                shiny::tags$br(), shiny::tags$br(),
                shiny::tags$strong("Quantization Error (QE): "),
                "Mean distance from each input point to its nearest CV. Lower = better fit.",
                shiny::tags$br(), shiny::tags$br(),
                shiny::tags$strong("Epochs: "),
                "SONG trains for a fixed number of self-organization passes over the data (default 50)."
              )
            )
          )
        )
      )
    }
  })

  output$song_graph_plot <- shiny::renderPlot({
    shiny::req(results$song_model)
    dark <- isTRUE(input$dark_mode)
    if (dark) graphics::par(bg = "#1a1d28", fg = "#e2e5ea",
                             col.axis = "#e2e5ea", col.lab = "#e2e5ea",
                             col.main = "#e2e5ea")
    plot(results$song_model, type = "graph", color_by = results$labels)
  }, bg = shiny::reactive({ plot_bg() }))

  output$song_summary <- shiny::renderPrint({
    shiny::req(results$song_model)
    summary(results$song_model)
  })

  fmt_time <- function(t) if (!is.na(t)) paste0(round(t, 2), "s") else "\u2014"

  output$timing_ui <- shiny::renderUI({
    shiny::tags$div(class = "timing-row",
      shiny::tags$div(class = "timing-pill t-song",
        shiny::tags$span(class = "t-label", "SONG"),
        shiny::tags$span(class = "t-value", fmt_time(results$song_time))
      ),
      shiny::tags$div(class = "timing-pill",
        shiny::tags$span(class = "t-label", "t-SNE"),
        shiny::tags$span(class = "t-value", fmt_time(results$tsne_time))
      ),
      shiny::tags$div(class = "timing-pill",
        shiny::tags$span(class = "t-label", "UMAP"),
        shiny::tags$span(class = "t-value", fmt_time(results$umap_time))
      )
    )
  })
}

shiny::shinyApp(ui, server)
