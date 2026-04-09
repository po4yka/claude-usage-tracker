"use strict";
(() => {
  // src/ui/app.tsx
  function esc(s) {
    const d = document.createElement("div");
    d.textContent = String(s);
    return d.innerHTML;
  }
  function $(id) {
    return document.getElementById(id);
  }
  function getTheme() {
    const stored = localStorage.getItem("theme");
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }
  function applyTheme(theme) {
    if (theme === "dark") {
      document.documentElement.setAttribute("data-theme", "dark");
    } else {
      document.documentElement.removeAttribute("data-theme");
    }
    const icon = document.getElementById("theme-icon");
    if (icon) icon.innerHTML = theme === "dark" ? "&#x2600;" : "&#x263E;";
    if (rawData) applyFilter();
  }
  function toggleTheme() {
    const current = document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
    const next = current === "dark" ? "light" : "dark";
    localStorage.setItem("theme", next);
    applyTheme(next);
  }
  applyTheme(getTheme());
  function apexThemeMode() {
    return document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
  }
  function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }
  var rawData = null;
  var selectedModels = /* @__PURE__ */ new Set();
  var selectedRange = "30d";
  var charts = {};
  var sessionSortCol = "last";
  var sessionSortDir = "desc";
  var modelSortCol = "cost";
  var modelSortDir = "desc";
  var projectSortCol = "cost";
  var projectSortDir = "desc";
  var lastFilteredSessions = [];
  var lastByProject = [];
  var projectSearchQuery = "";
  var sessionsCurrentPage = 0;
  var SESSIONS_PAGE_SIZE = 25;
  var previousSessionPercent = null;
  function isAnthropicModel(model) {
    if (!model) return false;
    const m = model.toLowerCase();
    return m.includes("opus") || m.includes("sonnet") || m.includes("haiku");
  }
  function fmt(n) {
    if (n >= 1e9) return (n / 1e9).toFixed(2) + "B";
    if (n >= 1e6) return (n / 1e6).toFixed(2) + "M";
    if (n >= 1e3) return (n / 1e3).toFixed(1) + "K";
    return n.toLocaleString();
  }
  function fmtCost(c) {
    return "$" + c.toFixed(4);
  }
  function fmtCostBig(c) {
    return "$" + c.toFixed(2);
  }
  var TOKEN_COLORS = {
    input: "rgba(79,142,247,0.8)",
    output: "rgba(167,139,250,0.8)",
    cache_read: "rgba(74,222,128,0.6)",
    cache_creation: "rgba(251,191,36,0.6)"
  };
  var MODEL_COLORS = ["#d97757", "#4f8ef7", "#4ade80", "#a78bfa", "#fbbf24", "#f472b6", "#34d399", "#60a5fa"];
  var RANGE_LABELS = {
    "7d": "Last 7 Days",
    "30d": "Last 30 Days",
    "90d": "Last 90 Days",
    "all": "All Time"
  };
  var RANGE_TICKS = { "7d": 7, "30d": 15, "90d": 13, "all": 12 };
  function getRangeCutoff(range) {
    if (range === "all") return null;
    const days = range === "7d" ? 7 : range === "30d" ? 30 : 90;
    const d = /* @__PURE__ */ new Date();
    d.setDate(d.getDate() - days);
    return d.toISOString().slice(0, 10);
  }
  function readURLRange() {
    const p = new URLSearchParams(window.location.search).get("range");
    return ["7d", "30d", "90d", "all"].includes(p) ? p : "30d";
  }
  function setRange(range) {
    selectedRange = range;
    document.querySelectorAll(".range-btn").forEach(
      (btn) => btn.classList.toggle("active", btn.dataset.range === range)
    );
    updateURL();
    applyFilter();
  }
  function modelPriority(m) {
    const ml = m.toLowerCase();
    if (ml.includes("opus")) return 0;
    if (ml.includes("sonnet")) return 1;
    if (ml.includes("haiku")) return 2;
    return 3;
  }
  function readURLModels(allModels) {
    const param = new URLSearchParams(window.location.search).get("models");
    if (!param) return new Set(allModels.filter((m) => isAnthropicModel(m)));
    const fromURL = new Set(param.split(",").map((s) => s.trim()).filter(Boolean));
    return new Set(allModels.filter((m) => fromURL.has(m)));
  }
  function isDefaultModelSelection(allModels) {
    const billable = allModels.filter((m) => isAnthropicModel(m));
    if (selectedModels.size !== billable.length) return false;
    return billable.every((m) => selectedModels.has(m));
  }
  function buildFilterUI(allModels) {
    const sorted = [...allModels].sort((a, b) => {
      const pa = modelPriority(a), pb = modelPriority(b);
      return pa !== pb ? pa - pb : a.localeCompare(b);
    });
    selectedModels = readURLModels(allModels);
    const container = $("model-checkboxes");
    container.innerHTML = sorted.map((m) => {
      const checked = selectedModels.has(m);
      return `<label class="model-cb-label ${checked ? "checked" : ""}" data-model="${esc(m)}">
      <input type="checkbox" value="${esc(m)}" ${checked ? "checked" : ""} onchange="onModelToggle(this)">
      ${esc(m)}
    </label>`;
    }).join("");
  }
  function onModelToggle(cb) {
    const label = cb.closest("label");
    if (cb.checked) {
      selectedModels.add(cb.value);
      label.classList.add("checked");
    } else {
      selectedModels.delete(cb.value);
      label.classList.remove("checked");
    }
    updateURL();
    applyFilter();
  }
  function selectAllModels() {
    document.querySelectorAll("#model-checkboxes input").forEach((cb) => {
      cb.checked = true;
      selectedModels.add(cb.value);
      cb.closest("label").classList.add("checked");
    });
    updateURL();
    applyFilter();
  }
  function clearAllModels() {
    document.querySelectorAll("#model-checkboxes input").forEach((cb) => {
      cb.checked = false;
      selectedModels.delete(cb.value);
      cb.closest("label").classList.remove("checked");
    });
    updateURL();
    applyFilter();
  }
  function onProjectSearch(query) {
    projectSearchQuery = query.toLowerCase().trim();
    const clearBtn = document.getElementById("project-clear-btn");
    if (clearBtn) clearBtn.style.display = projectSearchQuery ? "" : "none";
    updateURL();
    applyFilter();
  }
  function sessionsPage(delta) {
    const maxPage = Math.max(0, Math.ceil(lastFilteredSessions.length / SESSIONS_PAGE_SIZE) - 1);
    sessionsCurrentPage = Math.max(0, Math.min(maxPage, sessionsCurrentPage + delta));
    renderSessionsPage();
  }
  function renderSessionsPage() {
    const start = sessionsCurrentPage * SESSIONS_PAGE_SIZE;
    const page = lastFilteredSessions.slice(start, start + SESSIONS_PAGE_SIZE);
    renderSessionsTable(page);
    const total = lastFilteredSessions.length;
    const maxPage = Math.max(0, Math.ceil(total / SESSIONS_PAGE_SIZE) - 1);
    $("sessions-page-info").textContent = total > 0 ? `Showing ${start + 1}\u2013${Math.min(start + SESSIONS_PAGE_SIZE, total)} of ${total}` : "No sessions";
    $("sessions-prev").disabled = sessionsCurrentPage <= 0;
    $("sessions-next").disabled = sessionsCurrentPage >= maxPage;
  }
  function clearProjectSearch() {
    projectSearchQuery = "";
    const input = document.getElementById("project-search");
    if (input) input.value = "";
    const clearBtn = document.getElementById("project-clear-btn");
    if (clearBtn) clearBtn.style.display = "none";
    updateURL();
    applyFilter();
  }
  function matchesProjectSearch(project) {
    if (!projectSearchQuery) return true;
    return project.toLowerCase().includes(projectSearchQuery);
  }
  function updateURL() {
    const allModels = Array.from(document.querySelectorAll("#model-checkboxes input")).map((cb) => cb.value);
    const params = new URLSearchParams();
    if (selectedRange !== "30d") params.set("range", selectedRange);
    if (!isDefaultModelSelection(allModels)) params.set("models", Array.from(selectedModels).join(","));
    if (projectSearchQuery) params.set("project", projectSearchQuery);
    const search = params.toString() ? "?" + params.toString() : "";
    history.replaceState(null, "", window.location.pathname + search);
  }
  function setSessionSort(col) {
    if (sessionSortCol === col) sessionSortDir = sessionSortDir === "desc" ? "asc" : "desc";
    else {
      sessionSortCol = col;
      sessionSortDir = "desc";
    }
    updateSortIcons();
    applyFilter();
  }
  function updateSortIcons() {
    document.querySelectorAll(".sort-icon").forEach((el) => el.textContent = "");
    const icon = document.getElementById("sort-icon-" + sessionSortCol);
    if (icon) icon.textContent = sessionSortDir === "desc" ? " \u25BC" : " \u25B2";
  }
  function sortSessions(sessions) {
    return [...sessions].sort((a, b) => {
      let av, bv;
      if (sessionSortCol === "cost") {
        av = a.cost;
        bv = b.cost;
      } else if (sessionSortCol === "duration_min") {
        av = a.duration_min || 0;
        bv = b.duration_min || 0;
      } else {
        av = a[sessionSortCol] ?? 0;
        bv = b[sessionSortCol] ?? 0;
      }
      if (av < bv) return sessionSortDir === "desc" ? 1 : -1;
      if (av > bv) return sessionSortDir === "desc" ? -1 : 1;
      return 0;
    });
  }
  function setModelSort(col) {
    if (modelSortCol === col) modelSortDir = modelSortDir === "desc" ? "asc" : "desc";
    else {
      modelSortCol = col;
      modelSortDir = "desc";
    }
    updateModelSortIcons();
    applyFilter();
  }
  function updateModelSortIcons() {
    document.querySelectorAll('[id^="msort-"]').forEach((el) => el.textContent = "");
    const icon = document.getElementById("msort-" + modelSortCol);
    if (icon) icon.textContent = modelSortDir === "desc" ? " \u25BC" : " \u25B2";
  }
  function sortModels(byModel) {
    return [...byModel].sort((a, b) => {
      let av, bv;
      if (modelSortCol === "cost") {
        av = a.cost;
        bv = b.cost;
      } else {
        av = a[modelSortCol] ?? 0;
        bv = b[modelSortCol] ?? 0;
      }
      if (av < bv) return modelSortDir === "desc" ? 1 : -1;
      if (av > bv) return modelSortDir === "desc" ? -1 : 1;
      return 0;
    });
  }
  function setProjectSort(col) {
    if (projectSortCol === col) projectSortDir = projectSortDir === "desc" ? "asc" : "desc";
    else {
      projectSortCol = col;
      projectSortDir = "desc";
    }
    updateProjectSortIcons();
    applyFilter();
  }
  function updateProjectSortIcons() {
    document.querySelectorAll('[id^="psort-"]').forEach((el) => el.textContent = "");
    const icon = document.getElementById("psort-" + projectSortCol);
    if (icon) icon.textContent = projectSortDir === "desc" ? " \u25BC" : " \u25B2";
  }
  function sortProjects(byProject) {
    return [...byProject].sort((a, b) => {
      const av = a[projectSortCol] ?? 0;
      const bv = b[projectSortCol] ?? 0;
      if (av < bv) return projectSortDir === "desc" ? 1 : -1;
      if (av > bv) return projectSortDir === "desc" ? -1 : 1;
      return 0;
    });
  }
  function applyFilter() {
    if (!rawData) return;
    const cutoff = getRangeCutoff(selectedRange);
    const filteredDaily = rawData.daily_by_model.filter(
      (r) => selectedModels.has(r.model) && (!cutoff || r.day >= cutoff)
    );
    const dailyMap = {};
    for (const r of filteredDaily) {
      if (!dailyMap[r.day]) dailyMap[r.day] = { day: r.day, input: 0, output: 0, cache_read: 0, cache_creation: 0 };
      const d = dailyMap[r.day];
      d.input += r.input;
      d.output += r.output;
      d.cache_read += r.cache_read;
      d.cache_creation += r.cache_creation;
    }
    const daily = Object.values(dailyMap).sort((a, b) => a.day.localeCompare(b.day));
    const modelMap = {};
    for (const r of filteredDaily) {
      if (!modelMap[r.model]) modelMap[r.model] = { model: r.model, input: 0, output: 0, cache_read: 0, cache_creation: 0, turns: 0, sessions: 0, cost: 0, is_billable: r.cost > 0 || isAnthropicModel(r.model) };
      const m = modelMap[r.model];
      m.input += r.input;
      m.output += r.output;
      m.cache_read += r.cache_read;
      m.cache_creation += r.cache_creation;
      m.turns += r.turns;
      m.cost += r.cost;
    }
    const filteredSessions = rawData.sessions_all.filter(
      (s) => selectedModels.has(s.model) && (!cutoff || s.last_date >= cutoff) && matchesProjectSearch(s.project)
    );
    for (const s of filteredSessions) {
      if (modelMap[s.model]) modelMap[s.model].sessions++;
    }
    const byModel = Object.values(modelMap).sort((a, b) => b.input + b.output - (a.input + a.output));
    const projMap = {};
    for (const s of filteredSessions) {
      if (!projMap[s.project]) projMap[s.project] = { project: s.project, input: 0, output: 0, cache_read: 0, cache_creation: 0, turns: 0, sessions: 0, cost: 0 };
      const p = projMap[s.project];
      p.input += s.input;
      p.output += s.output;
      p.cache_read += s.cache_read;
      p.cache_creation += s.cache_creation;
      p.turns += s.turns;
      p.sessions++;
      p.cost += s.cost;
    }
    const byProject = Object.values(projMap).sort((a, b) => b.input + b.output - (a.input + a.output));
    const totals = {
      sessions: filteredSessions.length,
      turns: byModel.reduce((s, m) => s + m.turns, 0),
      input: byModel.reduce((s, m) => s + m.input, 0),
      output: byModel.reduce((s, m) => s + m.output, 0),
      cache_read: byModel.reduce((s, m) => s + m.cache_read, 0),
      cache_creation: byModel.reduce((s, m) => s + m.cache_creation, 0),
      cost: filteredSessions.reduce((s, sess) => s + sess.cost, 0)
    };
    $("daily-chart-title").textContent = "Daily Token Usage \u2014 " + RANGE_LABELS[selectedRange];
    renderStats(totals);
    renderCostSparkline(daily);
    renderDailyChart(daily);
    renderModelChart(byModel);
    renderProjectChart(byProject);
    lastFilteredSessions = sortSessions(filteredSessions);
    lastByProject = sortProjects(byProject);
    sessionsCurrentPage = 0;
    renderSessionsPage();
    renderModelCostTable(byModel);
    renderProjectCostTable(lastByProject.slice(0, 30));
  }
  function renderStats(t) {
    const rangeLabel = RANGE_LABELS[selectedRange].toLowerCase();
    const stats = [
      { label: "Sessions", value: t.sessions.toLocaleString(), sub: rangeLabel },
      { label: "Turns", value: fmt(t.turns), sub: rangeLabel },
      { label: "Input Tokens", value: fmt(t.input), sub: rangeLabel },
      { label: "Output Tokens", value: fmt(t.output), sub: rangeLabel },
      { label: "Cache Read", value: fmt(t.cache_read), sub: "from prompt cache" },
      { label: "Cache Creation", value: fmt(t.cache_creation), sub: "writes to prompt cache" },
      { label: "Est. Cost", value: fmtCostBig(t.cost), sub: "API pricing estimate", color: "#4ade80" }
    ];
    $("stats-row").innerHTML = stats.map((s) => `
    <div class="stat-card">
      <div class="label">${s.label}</div>
      <div class="value" style="${s.color ? "color:" + s.color : ""}">${esc(s.value)}</div>
      ${s.sub ? `<div class="sub">${esc(s.sub)}</div>` : ""}
    </div>
  `).join("");
  }
  function renderDailyChart(daily) {
    const el = document.getElementById("chart-daily");
    if (charts.daily) charts.daily.destroy();
    charts.daily = new ApexCharts(el, {
      chart: {
        type: "bar",
        height: "100%",
        stacked: true,
        background: "transparent",
        toolbar: { show: false },
        fontFamily: "inherit"
      },
      theme: { mode: apexThemeMode() },
      series: [
        { name: "Input", data: daily.map((d) => d.input) },
        { name: "Output", data: daily.map((d) => d.output) },
        { name: "Cache Read", data: daily.map((d) => d.cache_read) },
        { name: "Cache Creation", data: daily.map((d) => d.cache_creation) }
      ],
      colors: [TOKEN_COLORS.input, TOKEN_COLORS.output, TOKEN_COLORS.cache_read, TOKEN_COLORS.cache_creation],
      xaxis: {
        categories: daily.map((d) => d.day),
        labels: { rotate: -45, maxHeight: 60 },
        tickAmount: Math.min(daily.length, RANGE_TICKS[selectedRange])
      },
      yaxis: { labels: { formatter: (v) => fmt(v) } },
      legend: { position: "top", fontSize: "11px" },
      dataLabels: { enabled: false },
      tooltip: { y: { formatter: (v) => fmt(v) + " tokens" } },
      grid: { borderColor: cssVar("--chart-grid") },
      plotOptions: { bar: { columnWidth: "70%" } }
    });
    charts.daily.render();
  }
  function renderModelChart(byModel) {
    const el = document.getElementById("chart-model");
    if (charts.model) charts.model.destroy();
    if (!byModel.length) {
      charts.model = null;
      el.innerHTML = "";
      return;
    }
    charts.model = new ApexCharts(el, {
      chart: { type: "donut", height: "100%", background: "transparent", fontFamily: "inherit" },
      theme: { mode: apexThemeMode() },
      series: byModel.map((m) => m.input + m.output),
      labels: byModel.map((m) => m.model),
      colors: MODEL_COLORS.slice(0, byModel.length),
      legend: { position: "bottom", fontSize: "11px" },
      dataLabels: { enabled: false },
      tooltip: { y: { formatter: (v) => fmt(v) + " tokens" } },
      stroke: { width: 2, colors: [cssVar("--card")] },
      plotOptions: { pie: { donut: { size: "60%" } } }
    });
    charts.model.render();
  }
  function renderProjectChart(byProject) {
    const top = byProject.slice(0, 10);
    const el = document.getElementById("chart-project");
    if (charts.project) charts.project.destroy();
    if (!top.length) {
      charts.project = null;
      el.innerHTML = "";
      return;
    }
    charts.project = new ApexCharts(el, {
      chart: {
        type: "bar",
        height: "100%",
        background: "transparent",
        toolbar: { show: false },
        fontFamily: "inherit"
      },
      theme: { mode: apexThemeMode() },
      series: [
        { name: "Input", data: top.map((p) => p.input) },
        { name: "Output", data: top.map((p) => p.output) }
      ],
      colors: [TOKEN_COLORS.input, TOKEN_COLORS.output],
      plotOptions: { bar: { horizontal: true, barHeight: "60%" } },
      xaxis: {
        categories: top.map((p) => p.project.length > 22 ? "\u2026" + p.project.slice(-20) : p.project),
        labels: { formatter: (v) => fmt(v) }
      },
      yaxis: { labels: { maxWidth: 160 } },
      legend: { position: "top", fontSize: "11px" },
      dataLabels: { enabled: false },
      tooltip: { y: { formatter: (v) => fmt(v) + " tokens" } },
      grid: { borderColor: cssVar("--chart-grid") }
    });
    charts.project.render();
  }
  function renderSessionsTable(sessions) {
    $("sessions-body").innerHTML = sessions.map((s) => {
      const cost = s.cost;
      const costCell = s.is_billable ? `<td class="cost">${fmtCost(cost)}</td>` : `<td class="cost-na">n/a</td>`;
      return `<tr>
      <td class="muted" style="font-family:monospace">${esc(s.session_id)}&hellip;</td>
      <td>${esc(s.project)}</td>
      <td class="muted">${esc(s.last)}</td>
      <td class="muted">${esc(s.duration_min)}m</td>
      <td><span class="model-tag">${esc(s.model)}</span></td>
      <td class="num">${s.turns}${s.subagent_count > 0 ? `<span class="muted" style="font-size:10px"> (${s.subagent_count} agents)</span>` : ""}</td>
      <td class="num">${fmt(s.input)}</td>
      <td class="num">${fmt(s.output)}</td>
      ${costCell}
    </tr>`;
    }).join("");
  }
  function renderModelCostTable(byModel) {
    $("model-cost-body").innerHTML = sortModels(byModel).map((m) => {
      const cost = m.cost;
      const costCell = m.is_billable ? `<td class="cost">${fmtCost(cost)}</td>` : `<td class="cost-na">n/a</td>`;
      return `<tr>
      <td><span class="model-tag">${esc(m.model)}</span></td>
      <td class="num">${fmt(m.turns)}</td>
      <td class="num">${fmt(m.input)}</td>
      <td class="num">${fmt(m.output)}</td>
      <td class="num">${fmt(m.cache_read)}</td>
      <td class="num">${fmt(m.cache_creation)}</td>
      ${costCell}
    </tr>`;
    }).join("");
  }
  function renderProjectCostTable(byProject) {
    $("project-cost-body").innerHTML = sortProjects(byProject).map((p) => `<tr>
      <td>${esc(p.project)}</td>
      <td class="num">${p.sessions}</td>
      <td class="num">${fmt(p.turns)}</td>
      <td class="num">${fmt(p.input)}</td>
      <td class="num">${fmt(p.output)}</td>
      <td class="cost">${fmtCost(p.cost)}</td>
    </tr>`).join("");
  }
  function csvField(val) {
    const s = String(val);
    if (s.includes(",") || s.includes('"') || s.includes("\n")) {
      return '"' + s.replace(/"/g, '""') + '"';
    }
    return s;
  }
  function csvTimestamp() {
    const d = /* @__PURE__ */ new Date();
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0") + "_" + String(d.getHours()).padStart(2, "0") + String(d.getMinutes()).padStart(2, "0");
  }
  function downloadCSV(reportType, header, rows) {
    const lines = [header.map(csvField).join(",")];
    for (const row of rows) lines.push(row.map(csvField).join(","));
    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = reportType + "_" + csvTimestamp() + ".csv";
    a.click();
    URL.revokeObjectURL(a.href);
  }
  function exportSessionsCSV() {
    const header = ["Session", "Project", "Last Active", "Duration (min)", "Model", "Turns", "Input", "Output", "Cache Read", "Cache Creation", "Est. Cost"];
    const rows = lastFilteredSessions.map((s) => {
      const cost = s.cost;
      return [s.session_id, s.project, s.last, s.duration_min, s.model, s.turns, s.input, s.output, s.cache_read, s.cache_creation, cost.toFixed(4)];
    });
    downloadCSV("sessions", header, rows);
  }
  function exportProjectsCSV() {
    const header = ["Project", "Sessions", "Turns", "Input", "Output", "Cache Read", "Cache Creation", "Est. Cost"];
    const rows = lastByProject.map(
      (p) => [p.project, p.sessions, p.turns, p.input, p.output, p.cache_read, p.cache_creation, p.cost.toFixed(4)]
    );
    downloadCSV("projects", header, rows);
  }
  function progressColor(percent) {
    if (percent >= 90) return "#ef4444";
    if (percent >= 70) return "#fbbf24";
    return "#4ade80";
  }
  function fmtResetTime(minutes) {
    if (minutes == null || minutes <= 0) return "now";
    if (minutes >= 1440) return Math.floor(minutes / 1440) + "d " + Math.floor(minutes % 1440 / 60) + "h";
    if (minutes >= 60) return Math.floor(minutes / 60) + "h " + minutes % 60 + "m";
    return minutes + "m";
  }
  function renderWindowCard(label, w) {
    const pct = Math.min(100, w.used_percent);
    const color = progressColor(pct);
    const resetText = w.resets_in_minutes != null ? `Resets in ${fmtResetTime(w.resets_in_minutes)}` : "";
    return `<div class="stat-card">
    <div class="label">${esc(label)}</div>
    <div class="value" style="font-size:18px;color:${color}">${pct.toFixed(1)}%</div>
    <div style="background:var(--border);border-radius:4px;height:6px;margin:6px 0">
      <div style="background:${color};height:100%;border-radius:4px;width:${pct}%;transition:width 0.3s"></div>
    </div>
    <div class="sub">${esc(resetText)}</div>
  </div>`;
  }
  function renderUsageWindows(data) {
    const container = $("usage-windows");
    if (!container) return;
    if (!data.available) {
      container.innerHTML = "";
      container.style.display = "none";
      return;
    }
    container.style.display = "";
    let cards = "";
    if (data.session) cards += renderWindowCard("Session (5h)", data.session);
    if (data.weekly) cards += renderWindowCard("Weekly", data.weekly);
    if (data.weekly_opus) cards += renderWindowCard("Weekly Opus", data.weekly_opus);
    if (data.weekly_sonnet) cards += renderWindowCard("Weekly Sonnet", data.weekly_sonnet);
    if (data.budget) {
      const b = data.budget;
      const pct = Math.min(100, b.utilization);
      const color = progressColor(pct);
      cards += `<div class="stat-card">
      <div class="label">Monthly Budget</div>
      <div class="value" style="font-size:18px;color:${color}">$${b.used.toFixed(2)} / $${b.limit.toFixed(2)}</div>
      <div style="background:var(--border);border-radius:4px;height:6px;margin:6px 0">
        <div style="background:${color};height:100%;border-radius:4px;width:${pct}%;transition:width 0.3s"></div>
      </div>
      <div class="sub">${b.currency}</div>
    </div>`;
    }
    container.innerHTML = cards;
    if (data.session) {
      const currentPercent = 100 - data.session.used_percent;
      if (previousSessionPercent !== null) {
        if (previousSessionPercent > 0.01 && currentPercent <= 0.01) {
          showError("Session depleted \u2014 resets in " + fmtResetTime(data.session.resets_in_minutes));
        } else if (previousSessionPercent <= 0.01 && currentPercent > 0.01) {
          showSuccess("Session restored");
        }
      }
      previousSessionPercent = currentPercent;
    }
    const badge = $("plan-badge");
    if (badge && data.identity?.plan) {
      badge.textContent = data.identity.plan.charAt(0).toUpperCase() + data.identity.plan.slice(1);
      badge.style.display = "";
    } else if (badge) {
      badge.style.display = "none";
    }
  }
  function showSuccess(msg) {
    const el = document.createElement("div");
    el.style.cssText = "position:fixed;top:16px;right:16px;background:var(--toast-success-bg);color:var(--toast-success-text);padding:12px 20px;border-radius:8px;font-size:13px;z-index:999;max-width:400px;box-shadow:0 4px 12px rgba(0,0,0,0.15)";
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 6e3);
  }
  function renderSubagentSummary(summary) {
    const container = $("subagent-summary");
    if (!container) return;
    if (summary.subagent_turns === 0) {
      container.style.display = "none";
      return;
    }
    container.style.display = "";
    const totalInput = summary.parent_input + summary.subagent_input;
    const totalOutput = summary.parent_output + summary.subagent_output;
    const subPctInput = totalInput > 0 ? summary.subagent_input / totalInput * 100 : 0;
    const subPctOutput = totalOutput > 0 ? summary.subagent_output / totalOutput * 100 : 0;
    container.innerHTML = `
    <div class="section-title">Subagent Breakdown</div>
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px">
      <div>
        <div class="label" style="color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px">Turns</div>
        <div style="font-size:15px">Parent: <strong>${fmt(summary.parent_turns)}</strong></div>
        <div style="font-size:15px">Subagent: <strong>${fmt(summary.subagent_turns)}</strong></div>
        <div class="sub">${summary.unique_agents} unique agents</div>
      </div>
      <div>
        <div class="label" style="color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px">Input Tokens</div>
        <div style="font-size:15px">Parent: <strong>${fmt(summary.parent_input)}</strong></div>
        <div style="font-size:15px">Subagent: <strong>${fmt(summary.subagent_input)}</strong> (${subPctInput.toFixed(1)}%)</div>
      </div>
      <div>
        <div class="label" style="color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px">Output Tokens</div>
        <div style="font-size:15px">Parent: <strong>${fmt(summary.parent_output)}</strong></div>
        <div style="font-size:15px">Subagent: <strong>${fmt(summary.subagent_output)}</strong> (${subPctOutput.toFixed(1)}%)</div>
      </div>
    </div>
  `;
  }
  function renderEntrypointBreakdown(data) {
    const container = $("entrypoint-breakdown");
    if (!container) return;
    if (!data.length) {
      container.style.display = "none";
      return;
    }
    container.style.display = "";
    container.innerHTML = `
    <div class="section-title">Usage by Entrypoint</div>
    <table><thead><tr>
      <th>Entrypoint</th><th>Sessions</th><th>Turns</th><th>Input</th><th>Output</th>
    </tr></thead><tbody>${data.map((e) => `<tr>
      <td><span class="model-tag">${esc(e.entrypoint)}</span></td>
      <td class="num">${e.sessions}</td>
      <td class="num">${fmt(e.turns)}</td>
      <td class="num">${fmt(e.input)}</td>
      <td class="num">${fmt(e.output)}</td>
    </tr>`).join("")}</tbody></table>`;
  }
  function renderServiceTiers(data) {
    const container = $("service-tiers");
    if (!container) return;
    if (!data.length) {
      container.style.display = "none";
      return;
    }
    container.style.display = "";
    container.innerHTML = `
    <div class="section-title">Service Tiers</div>
    <table><thead><tr>
      <th>Tier</th><th>Region</th><th>Turns</th>
    </tr></thead><tbody>${data.map((s) => `<tr>
      <td>${esc(s.service_tier)}</td>
      <td>${esc(s.inference_geo)}</td>
      <td class="num">${fmt(s.turns)}</td>
    </tr>`).join("")}</tbody></table>`;
  }
  function renderCostSparkline(daily) {
    const container = $("cost-sparkline");
    if (!container) return;
    const last7 = daily.slice(-7);
    if (last7.length < 2) {
      container.style.display = "none";
      return;
    }
    container.style.display = "";
    container.innerHTML = '<div class="sub" style="margin-bottom:4px">7-day trend</div><div id="sparkline-chart"></div>';
    if (charts.sparkline) charts.sparkline.destroy();
    charts.sparkline = new ApexCharts(document.getElementById("sparkline-chart"), {
      chart: {
        type: "line",
        height: 30,
        width: 120,
        sparkline: { enabled: true },
        background: "transparent",
        fontFamily: "inherit"
      },
      series: [{ data: last7.map((d) => d.input + d.output) }],
      stroke: { width: 1.5, curve: "smooth" },
      colors: [cssVar("--accent")],
      tooltip: { enabled: false }
    });
    charts.sparkline.render();
  }
  async function loadUsageWindows() {
    try {
      const resp = await fetch("/api/usage-windows");
      if (!resp.ok) return;
      const data = await resp.json();
      renderUsageWindows(data);
    } catch {
    }
  }
  function showError(msg) {
    const el = document.createElement("div");
    el.style.cssText = "position:fixed;top:16px;right:16px;background:var(--toast-error-bg);color:var(--toast-error-text);padding:12px 20px;border-radius:8px;font-size:13px;z-index:999;max-width:400px;box-shadow:0 4px 12px rgba(0,0,0,0.15)";
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 6e3);
  }
  async function triggerRescan() {
    const btn = $("rescan-btn");
    btn.disabled = true;
    btn.textContent = "\u21BB Scanning...";
    try {
      const resp = await fetch("/api/rescan", { method: "POST" });
      if (!resp.ok) {
        showError(`Rescan failed: HTTP ${resp.status} ${resp.statusText}`);
        btn.textContent = "\u21BB Rescan (failed)";
        return;
      }
      const d = await resp.json();
      btn.textContent = "\u21BB Rescan (" + d.new + " new, " + d.updated + " updated)";
      await loadData();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      showError("Rescan failed: " + msg);
      btn.textContent = "\u21BB Rescan (error)";
      console.error(e);
    }
    setTimeout(() => {
      btn.textContent = "\u21BB Rescan";
      btn.disabled = false;
    }, 3e3);
  }
  async function loadData() {
    try {
      const resp = await fetch("/api/data");
      if (!resp.ok) {
        showError(`Failed to load data: HTTP ${resp.status}`);
        return;
      }
      const d = await resp.json();
      if (d.error) {
        document.body.innerHTML = '<div style="padding:40px;color:#f87171;font-family:monospace">' + esc(d.error) + "</div>";
        return;
      }
      $("meta").textContent = "Updated: " + d.generated_at + " \xB7 Auto-refresh 30s";
      const isFirstLoad = rawData === null;
      rawData = d;
      if (isFirstLoad) {
        selectedRange = readURLRange();
        document.querySelectorAll(".range-btn").forEach(
          (btn) => btn.classList.toggle("active", btn.dataset.range === selectedRange)
        );
        buildFilterUI(d.all_models);
        updateSortIcons();
        updateModelSortIcons();
        updateProjectSortIcons();
        const urlProject = new URLSearchParams(window.location.search).get("project");
        if (urlProject) {
          projectSearchQuery = urlProject;
          const input = document.getElementById("project-search");
          if (input) input.value = urlProject;
          const clearBtn = document.getElementById("project-clear-btn");
          if (clearBtn) clearBtn.style.display = "";
        }
      }
      applyFilter();
      if (rawData.subagent_summary) renderSubagentSummary(rawData.subagent_summary);
      if (rawData.entrypoint_breakdown) renderEntrypointBreakdown(rawData.entrypoint_breakdown);
      if (rawData.service_tiers) renderServiceTiers(rawData.service_tiers);
    } catch (e) {
      console.error(e);
    }
  }
  Object.assign(window, {
    setRange,
    onModelToggle,
    selectAllModels,
    clearAllModels,
    setSessionSort,
    setModelSort,
    setProjectSort,
    exportSessionsCSV,
    exportProjectsCSV,
    triggerRescan,
    onProjectSearch,
    clearProjectSearch,
    sessionsPage,
    toggleTheme
  });
  loadData();
  setInterval(loadData, 3e4);
  loadUsageWindows();
  setInterval(loadUsageWindows, 6e4);
})();
