function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

const chartRefs = {};
let lastPayload = null;

function readTheme() {
  const styles = getComputedStyle(document.documentElement);
  const pick = (name) => styles.getPropertyValue(name).trim();
  return {
    text: pick("--text") || "#1b2433",
    muted: pick("--text-muted") || "#667085",
    grid: pick("--chart-grid") || "rgba(21, 27, 40, 0.08)",
    c1: pick("--chart-1") || "#1f9d62",
    c2: pick("--chart-2") || "#3d5a96",
    c3: pick("--chart-3") || "#c5364e",
    c4: pick("--chart-4") || "#d4a017",
  };
}

function applyChartDefaults() {
  const theme = readTheme();
  Chart.defaults.color = theme.muted;
  Chart.defaults.font.family = "Inter, system-ui, sans-serif";
  Chart.defaults.plugins.legend.labels.boxWidth = 10;
  Chart.defaults.plugins.legend.labels.usePointStyle = true;
}

function mountChart(id, config) {
  const canvas = document.getElementById(id);
  if (!canvas || typeof Chart === "undefined") return;
  if (chartRefs[id]) chartRefs[id].destroy();
  chartRefs[id] = new Chart(canvas, config);
}

function scales() {
  const theme = readTheme();
  const axis = {
    ticks: { color: theme.muted },
    grid: { color: theme.grid },
    border: { display: false },
  };
  return {
    x: { ...axis, stacked: false },
    y: { ...axis, beginAtZero: true },
  };
}

function draw(stats) {
  applyChartDefaults();
  const theme = readTheme();
  const departments = stats.byDepartment || [];

  mountChart("chartDepartments", {
    type: "doughnut",
    data: {
      labels: departments.map((item) => item.code),
      datasets: [
        {
          data: departments.map((item) => item.count),
          backgroundColor: [theme.c1, theme.c2, theme.c4],
          borderWidth: 0,
        },
      ],
    },
    options: {
      maintainAspectRatio: false,
      plugins: { legend: { position: "bottom" } },
    },
  });

  const semesters = [1, 2, 3, 4];
  const countFor = (semester, section) => {
    const row = (stats.bySemesterSection || []).find(
      (item) => item.semester === semester && item.section === section
    );
    return row ? row.count : 0;
  };

  mountChart("chartSemesters", {
    type: "bar",
    data: {
      labels: semesters.map((semester) => `Semester ${semester}`),
      datasets: [
        {
          label: "Section A",
          data: semesters.map((semester) => countFor(semester, "A")),
          backgroundColor: theme.c1,
          stack: "cohort",
          borderRadius: 6,
        },
        {
          label: "Section B",
          data: semesters.map((semester) => countFor(semester, "B")),
          backgroundColor: theme.c2,
          stack: "cohort",
          borderRadius: 6,
        },
      ],
    },
    options: {
      maintainAspectRatio: false,
      scales: {
        x: { ...scales().x, stacked: true },
        y: { ...scales().y, stacked: true, ticks: { precision: 0, color: theme.muted } },
      },
    },
  });

  mountChart("chartAttendance", {
    type: "bar",
    data: {
      labels: departments.map((item) => item.code),
      datasets: [
        {
          label: "Average attendance",
          data: departments.map((item) => item.averageAttendance ?? 0),
          backgroundColor: theme.c1,
          borderRadius: 8,
        },
      ],
    },
    options: {
      indexAxis: "y",
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { ...scales().x, max: 100 },
        y: scales().y,
      },
    },
  });

  const bands = stats.cgpaBands || [];
  mountChart("chartCgpa", {
    type: "bar",
    data: {
      labels: bands.map((band) => band.label),
      datasets: [
        {
          label: "Students",
          data: bands.map((band) => band.count),
          backgroundColor: theme.c2,
          borderRadius: 6,
        },
      ],
    },
    options: {
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: scales().x,
        y: { ...scales().y, ticks: { precision: 0, color: theme.muted } },
      },
    },
  });
}

function renderAtRisk(rows) {
  const body = document.getElementById("atRiskBody");
  if (!body) return;
  if (!rows.length) {
    body.innerHTML = '<tr><td colspan="3" class="empty-cell">No students are below 75% attendance.</td></tr>';
    return;
  }

  body.innerHTML = "";
  rows.forEach((row) => {
    const tr = document.createElement("tr");
    const level = row.attendancePercent >= 60 ? "attendance-mid" : "attendance-low";
    tr.innerHTML = `
      <td>
        <strong>${escapeHtml(row.name)}</strong>
        <div class="meta">${escapeHtml(row.registrationNumber)}</div>
      </td>
      <td>${escapeHtml(row.department)} · Sem ${escapeHtml(row.semester)} · ${escapeHtml(row.section)}</td>
      <td>
        <div class="attendance-cell">
          <div class="progress"><div class="progress-fill ${level}" style="width:${row.attendancePercent}%"></div></div>
          <span class="attendance-label">${row.attendancePercent}%</span>
        </div>
      </td>
    `;
    body.appendChild(tr);
  });
}

function showDashboardError(message) {
  const banner = document.getElementById("dashboardError");
  if (!banner) return;
  if (!message) {
    banner.classList.add("hidden");
    banner.textContent = "";
    return;
  }
  banner.textContent = message;
  banner.classList.remove("hidden");
}

export async function loadDashboard(refresh = false) {
  showDashboardError("");
  const refreshBtn = document.getElementById("refreshStatsBtn");
  if (refreshBtn) refreshBtn.disabled = true;
  try {
    const response = await fetch(`/api/stats${refresh ? "?refresh=true" : ""}`);
    const text = await response.text();
    const data = text ? JSON.parse(text) : null;
    if (!response.ok) {
      const detail = data?.detail;
      throw new Error(typeof detail === "string" ? detail : "Could not load cohort analytics");
    }
    lastPayload = data;
    document.getElementById("kpiTotal").textContent = String(data.totalStudents ?? "—");
    document.getElementById("kpiCgpa").textContent =
      data.averageCgpa == null ? "—" : Number(data.averageCgpa).toFixed(2);
    document.getElementById("kpiAttendance").textContent =
      data.averageAttendance == null ? "—" : `${Number(data.averageAttendance).toFixed(1)}%`;
    document.getElementById("kpiPending").textContent = String(data.pendingDocuments ?? "—");
    const chip = document.getElementById("kpiTotalChip");
    if (chip) chip.textContent = data.cached ? "Cached · 24 cohorts" : "Live · 24 cohorts";
    draw(data);
    renderAtRisk(data.atRisk || []);
  } catch (error) {
    showDashboardError(error.message || "Could not load cohort analytics");
    const body = document.getElementById("atRiskBody");
    if (body && !lastPayload) {
      body.innerHTML = '<tr><td colspan="3" class="empty-cell">Analytics are unavailable right now.</td></tr>';
    }
  } finally {
    if (refreshBtn) refreshBtn.disabled = false;
  }
}

export function restyleCharts() {
  if (lastPayload) draw(lastPayload);
}

document.getElementById("refreshStatsBtn")?.addEventListener("click", () => {
  loadDashboard(true);
});

document.addEventListener("aicc-theme", () => restyleCharts());
