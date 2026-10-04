import { loadDashboard } from "./dashboard.js";

const API = "/api";

let catalog = null;
let selectedStudentId = null;
let isNewStudent = false;
let loadedStudents = [];
let searchQuery = "";

const els = {
  status: document.getElementById("status"),
  statusMessage: document.getElementById("statusMessage"),
  toastTitle: document.getElementById("toastTitle"),
  toastBackdrop: document.getElementById("toastBackdrop"),
  closeToastBtn: document.getElementById("closeToastBtn"),
  dismissToastBtn: document.getElementById("dismissToastBtn"),
  headerUserLabel: document.getElementById("headerUserLabel"),
  statTotalStudents: document.getElementById("statTotalStudents"),
  statDepartment: document.getElementById("statDepartment"),
  statSemester: document.getElementById("statSemester"),
  statCgpa: document.getElementById("statCgpa"),
  filterDepartment: document.getElementById("filterDepartment"),
  filterSemester: document.getElementById("filterSemester"),
  filterSection: document.getElementById("filterSection"),
  applyFilterBtn: document.getElementById("applyFilterBtn"),
  newStudentBtn: document.getElementById("newStudentBtn"),
  studentSearch: document.getElementById("studentSearch"),
  studentList: document.getElementById("studentList"),
  studentCount: document.getElementById("studentCount"),
  emptyState: document.getElementById("emptyState"),
  studentPanel: document.getElementById("studentPanel"),
  panelTitle: document.getElementById("panelTitle"),
  studentForm: document.getElementById("studentForm"),
  studentId: document.getElementById("studentId"),
  name: document.getElementById("name"),
  registrationNumber: document.getElementById("registrationNumber"),
  department: document.getElementById("department"),
  semester: document.getElementById("semester"),
  section: document.getElementById("section"),
  cgpaOverall: document.getElementById("cgpaOverall"),
  saveStudentBtn: document.getElementById("saveStudentBtn"),
  deleteStudentBtn: document.getElementById("deleteStudentBtn"),
  coursesContainer: document.getElementById("coursesContainer"),
  courseForm: document.getElementById("courseForm"),
  courseName: document.getElementById("courseName"),
  courseCode: document.getElementById("courseCode"),
  courseAttendance: document.getElementById("courseAttendance"),
  courseSemester: document.getElementById("courseSemester"),
  notificationsBody: document.getElementById("notificationsBody"),
  notificationForm: document.getElementById("notificationForm"),
  notificationType: document.getElementById("notificationType"),
  notificationMessage: document.getElementById("notificationMessage"),
  notificationRead: document.getElementById("notificationRead"),
  documentsBody: document.getElementById("documentsBody"),
  documentForm: document.getElementById("documentForm"),
  documentType: document.getElementById("documentType"),
  documentStatus: document.getElementById("documentStatus"),
  documentFileUrl: document.getElementById("documentFileUrl"),
  confirmModal: document.getElementById("confirmModal"),
  confirmMessage: document.getElementById("confirmMessage"),
  confirmCancel: document.getElementById("confirmCancel"),
  confirmOk: document.getElementById("confirmOk"),
  pageKicker: document.getElementById("pageKicker"),
  pageTitle: document.getElementById("pageTitle"),
  viewDashboard: document.getElementById("viewDashboard"),
  viewStudents: document.getElementById("viewStudents"),
  themeToggle: document.getElementById("themeToggle"),
  themeLabel: document.getElementById("themeLabel"),
  collapseToggle: document.getElementById("collapseToggle"),
};

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function formatCgpa(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number.toFixed(2) : "—";
}

function hideToast() {
  els.status.classList.add("hidden");
  els.toastBackdrop.classList.add("hidden");
}

function showStatus(message, type = "success") {
  els.statusMessage.textContent = message;
  els.toastTitle.textContent = type === "error" ? "Something went wrong" : "Saved";
  els.status.className = `toast ${type}`;
  clearTimeout(showStatus._timer);
  showStatus._timer = setTimeout(hideToast, 3200);
}

function askConfirm(message) {
  els.confirmMessage.textContent = message;
  els.confirmModal.classList.remove("hidden");
  return new Promise((resolve) => {
    const finish = (accepted) => {
      els.confirmModal.classList.add("hidden");
      els.confirmOk.removeEventListener("click", onOk);
      els.confirmCancel.removeEventListener("click", onCancel);
      document.removeEventListener("keydown", onKey);
      resolve(accepted);
    };
    const onOk = () => finish(true);
    const onCancel = () => finish(false);
    const onKey = (event) => {
      if (event.key === "Escape") finish(false);
    };
    els.confirmOk.addEventListener("click", onOk);
    els.confirmCancel.addEventListener("click", onCancel);
    document.addEventListener("keydown", onKey);
  });
}

function attendanceClass(percent) {
  if (percent >= 75) return "attendance-high";
  if (percent >= 60) return "attendance-mid";
  return "attendance-low";
}

function cgpaClass(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return "";
  if (number >= 3) return "";
  if (number >= 2) return "mid";
  return "low";
}

function initials(name) {
  const parts = String(name || "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  return parts.slice(0, 2).map((part) => part[0].toUpperCase()).join("");
}

function updateStats(students, student = null) {
  els.statTotalStudents.textContent = String(students.length);
  if (student) {
    els.statDepartment.textContent = student.department || "—";
    els.statSemester.textContent = student.semester ? `Semester ${student.semester}` : "—";
    els.statCgpa.textContent = formatCgpa(student.cgpaOverall);
    els.headerUserLabel.textContent = student.registrationNumber || "Administrator";
  } else if (isNewStudent) {
    els.statDepartment.textContent = els.department.value || "—";
    els.statSemester.textContent = els.semester.value ? `Semester ${els.semester.value}` : "—";
    els.statCgpa.textContent = els.cgpaOverall.value ? formatCgpa(els.cgpaOverall.value) : "—";
    els.headerUserLabel.textContent = "New Student";
  } else {
    els.statDepartment.textContent = "—";
    els.statSemester.textContent = "—";
    els.statCgpa.textContent = "—";
    els.headerUserLabel.textContent = "Administrator";
  }
}

async function api(path, options = {}) {
  const response = await fetch(`${API}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });

  if (response.status === 204) {
    return null;
  }

  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const detail = data?.detail;
    const message = Array.isArray(detail)
      ? detail.map((item) => item.msg || JSON.stringify(item)).join(", ")
      : detail || response.statusText;
    throw new Error(message);
  }

  return data;
}

function fillSelect(select, options, includeAll = false) {
  select.innerHTML = "";
  if (includeAll) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "All";
    select.appendChild(option);
  }
  options.forEach((item) => {
    const option = document.createElement("option");
    if (typeof item === "object") {
      option.value = item.code;
      option.textContent = `${item.code} — ${item.name}`;
    } else {
      option.value = String(item);
      option.textContent = String(item);
    }
    select.appendChild(option);
  });
}

function populateCatalogDropdowns() {
  fillSelect(els.filterDepartment, catalog.departments, true);
  fillSelect(els.filterSemester, catalog.semesters, true);
  fillSelect(els.filterSection, catalog.sections, true);
  fillSelect(els.department, catalog.departments);
  fillSelect(els.semester, catalog.semesters);
  fillSelect(els.section, catalog.sections);
  fillSelect(els.courseSemester, catalog.semesters);
}

function visibleStudents() {
  const query = searchQuery.trim().toLowerCase();
  if (!query) return loadedStudents;
  return loadedStudents.filter((student) => {
    const name = (student.name || "").toLowerCase();
    const registration = (student.registrationNumber || "").toLowerCase();
    return name.includes(query) || registration.includes(query);
  });
}

function renderSkeletonList() {
  els.studentList.innerHTML = Array.from({ length: 6 }, () => `
    <li class="skeleton-row">
      <span class="skeleton avatar"></span>
      <span class="skeleton line"></span>
    </li>
  `).join("");
}

function renderStudentList() {
  const students = visibleStudents();
  els.studentList.innerHTML = "";
  els.studentCount.textContent = String(students.length);

  if (students.length === 0) {
    els.studentList.innerHTML = '<li class="empty-list">No students match this filter.</li>';
    return;
  }

  students.forEach((student) => {
    const li = document.createElement("li");
    li.dataset.id = student.id;
    if (student.id === selectedStudentId) li.classList.add("active");
    const cgpa = formatCgpa(student.cgpaOverall);
    li.innerHTML = `
      <span class="avatar dept-${escapeHtml(student.department)}">${escapeHtml(initials(student.name))}</span>
      <div class="student-copy">
        <strong>${escapeHtml(student.name)}</strong>
        <div class="reg">${escapeHtml(student.registrationNumber)}</div>
        <div class="meta">${escapeHtml(student.department)} · Sem ${escapeHtml(student.semester)} · ${escapeHtml(student.section)}</div>
      </div>
      <span class="cgpa-chip ${cgpaClass(student.cgpaOverall)}">${cgpa}</span>
    `;
    li.addEventListener("click", () => selectStudent(student.id));
    els.studentList.appendChild(li);
  });
}

async function loadStudents() {
  renderSkeletonList();
  const params = new URLSearchParams();
  if (els.filterDepartment.value) params.set("department", els.filterDepartment.value);
  if (els.filterSemester.value) params.set("semester", els.filterSemester.value);
  if (els.filterSection.value) params.set("section", els.filterSection.value);

  const query = params.toString();
  const students = await api(`/students${query ? `?${query}` : ""}`);
  loadedStudents = students;
  renderStudentList();

  if (selectedStudentId && !isNewStudent) {
    const current = students.find((student) => student.id === selectedStudentId);
    updateStats(students, current || null);
  } else {
    updateStats(students);
  }

  return students;
}

function showStudentPanel(title) {
  els.emptyState.classList.add("hidden");
  els.studentPanel.classList.remove("hidden");
  els.panelTitle.textContent = title;
}

function showTab(name) {
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.tab === name);
  });
  document.querySelectorAll(".tab-panel").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.panel !== name);
  });
}

function clearSubcollections() {
  els.coursesContainer.innerHTML = '<p class="empty-sub">No courses yet.</p>';
  els.notificationsBody.innerHTML = '<tr><td colspan="5" class="empty-cell">No notifications.</td></tr>';
  els.documentsBody.innerHTML = '<tr><td colspan="4" class="empty-cell">No documents.</td></tr>';
}

function renderCourses(courses) {
  els.coursesContainer.innerHTML = "";
  if (courses.length === 0) {
    els.coursesContainer.innerHTML = '<p class="empty-sub">No courses yet.</p>';
    return;
  }

  const grouped = {};
  courses.forEach((course) => {
    if (!grouped[course.semester]) grouped[course.semester] = [];
    grouped[course.semester].push(course);
  });

  Object.keys(grouped)
    .sort((a, b) => Number(a) - Number(b))
    .forEach((semester) => {
      const section = document.createElement("div");
      section.className = "semester-group";
      section.innerHTML = `<h4>Semester ${semester}</h4>`;

      const table = document.createElement("table");
      table.className = "data-table";
      table.innerHTML = `
        <thead>
          <tr>
            <th>Code</th>
            <th>Course name</th>
            <th>Attendance</th>
            <th></th>
          </tr>
        </thead>
        <tbody></tbody>
      `;

      const tbody = table.querySelector("tbody");
      grouped[semester].forEach((course) => {
        const row = document.createElement("tr");
        const level = attendanceClass(course.attendancePercent);
        const width = Math.max(0, Math.min(100, Number(course.attendancePercent) || 0));
        row.innerHTML = `
          <td><strong>${escapeHtml(course.courseCode)}</strong></td>
          <td>${escapeHtml(course.courseName)}</td>
          <td>
            <div class="attendance-cell">
              <div class="progress"><div class="progress-fill ${level}" style="width:${width}%"></div></div>
              <span class="attendance-label">${course.attendancePercent}%</span>
            </div>
          </td>
          <td><button type="button" class="table-btn danger">Delete</button></td>
        `;
        row.querySelector("button").addEventListener("click", () => deleteCourse(course.id));
        tbody.appendChild(row);
      });

      section.appendChild(table);
      els.coursesContainer.appendChild(section);
    });
}

function renderNotifications(notifications) {
  els.notificationsBody.innerHTML = "";
  if (notifications.length === 0) {
    els.notificationsBody.innerHTML = '<tr><td colspan="5" class="empty-cell">No notifications.</td></tr>';
    return;
  }

  notifications.forEach((item) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${escapeHtml(item.type.replace(/_/g, " "))}</td>
      <td>${escapeHtml(item.message)}</td>
      <td>${item.timestamp ? new Date(item.timestamp).toLocaleString() : "—"}</td>
      <td>${item.read ? "Read" : "Unread"}</td>
      <td>
        <button type="button" class="table-btn" data-read="${!item.read}">
          ${item.read ? "Unread" : "Read"}
        </button>
        <button type="button" class="table-btn danger">Delete</button>
      </td>
    `;
    row.querySelector("[data-read]").addEventListener("click", (event) => {
      updateNotification(item.id, event.currentTarget.dataset.read === "true");
    });
    row.querySelector(".danger").addEventListener("click", () => deleteNotification(item.id));
    els.notificationsBody.appendChild(row);
  });
}

function renderDocuments(documents) {
  els.documentsBody.innerHTML = "";
  if (documents.length === 0) {
    els.documentsBody.innerHTML = '<tr><td colspan="4" class="empty-cell">No documents.</td></tr>';
    return;
  }

  documents.forEach((item) => {
    const row = document.createElement("tr");
    const statusClass = item.status === "ready" ? "status-ready" : "status-pending";
    row.innerHTML = `
      <td>${escapeHtml(item.docType.replace(/_/g, " "))}</td>
      <td><span class="status-badge ${statusClass}">${escapeHtml(item.status)}</span></td>
      <td>${item.fileUrl ? `<a href="${escapeHtml(item.fileUrl)}" target="_blank" rel="noopener">Open document</a>` : "—"}</td>
      <td><button type="button" class="table-btn danger">Delete</button></td>
    `;
    row.querySelector("button").addEventListener("click", () => deleteDocument(item.id));
    els.documentsBody.appendChild(row);
  });
}

async function loadSubcollections(studentId) {
  const [courses, notifications, documents] = await Promise.all([
    api(`/students/${studentId}/courses`),
    api(`/students/${studentId}/notifications`),
    api(`/students/${studentId}/documents`),
  ]);
  renderCourses(courses);
  renderNotifications(notifications);
  renderDocuments(documents);
}

function fillStudentForm(student) {
  els.studentId.value = student.id || "";
  els.name.value = student.name || "";
  els.registrationNumber.value = student.registrationNumber || "";
  els.department.value = student.department || catalog.departments[0].code;
  els.semester.value = String(student.semester || catalog.semesters[0]);
  els.section.value = student.section || catalog.sections[0];
  els.cgpaOverall.value = student.cgpaOverall ?? "";
}

async function selectStudent(studentId) {
  isNewStudent = false;
  selectedStudentId = studentId;
  const student = await api(`/students/${studentId}`);
  showStudentPanel(student.name || student.registrationNumber);
  showTab("profile");
  fillStudentForm(student);
  await loadSubcollections(studentId);
  const students = await loadStudents();
  updateStats(students, student);
}

function startNewStudent() {
  isNewStudent = true;
  selectedStudentId = null;
  showStudentPanel("New student record");
  showTab("profile");
  fillStudentForm({
    department: catalog.departments[0].code,
    semester: catalog.semesters[0],
    section: catalog.sections[0],
    cgpaOverall: 3.0,
  });
  els.studentId.value = "";
  els.name.value = "";
  els.registrationNumber.value = "";
  clearSubcollections();
  renderStudentList();
  loadStudents().then((students) => updateStats(students));
}

function readStudentForm() {
  return {
    name: els.name.value.trim(),
    registrationNumber: els.registrationNumber.value.trim(),
    department: els.department.value,
    semester: Number(els.semester.value),
    section: els.section.value,
    cgpaOverall: Number(els.cgpaOverall.value),
  };
}

async function saveStudent() {
  const payload = readStudentForm();

  if (isNewStudent) {
    const created = await api("/students", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    isNewStudent = false;
    selectedStudentId = created.id;
    showStatus("Student record created.");
  } else {
    await api(`/students/${selectedStudentId}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
    if (payload.registrationNumber !== selectedStudentId) {
      selectedStudentId = payload.registrationNumber;
    }
    showStatus("Student record updated.");
  }

  await selectStudent(selectedStudentId);
}

async function deleteStudent() {
  if (!selectedStudentId || isNewStudent) return;
  const accepted = await askConfirm(
    `Delete ${selectedStudentId}? This removes the student and every course, notification, and document under them.`
  );
  if (!accepted) return;

  await api(`/students/${selectedStudentId}`, { method: "DELETE" });
  selectedStudentId = null;
  isNewStudent = false;
  els.studentPanel.classList.add("hidden");
  els.emptyState.classList.remove("hidden");
  clearSubcollections();
  showStatus("Student record deleted.");
  await loadStudents();
}

async function addCourse(event) {
  event.preventDefault();
  if (!selectedStudentId) return;

  const payload = {
    courseName: els.courseName.value.trim(),
    courseCode: els.courseCode.value.trim(),
    attendancePercent: Number(els.courseAttendance.value),
    semester: Number(els.courseSemester.value),
  };

  await api(`/students/${selectedStudentId}/courses`, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  els.courseForm.reset();
  els.courseSemester.value = els.semester.value;
  showStatus("Course added.");
  await loadSubcollections(selectedStudentId);
}

async function deleteCourse(courseId) {
  if (!selectedStudentId) return;
  await api(`/students/${selectedStudentId}/courses/${courseId}`, { method: "DELETE" });
  showStatus("Course removed.");
  await loadSubcollections(selectedStudentId);
}

async function addNotification(event) {
  event.preventDefault();
  if (!selectedStudentId) return;

  const payload = {
    type: els.notificationType.value,
    message: els.notificationMessage.value.trim(),
    read: els.notificationRead.checked,
  };

  await api(`/students/${selectedStudentId}/notifications`, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  els.notificationForm.reset();
  showStatus("Notification added.");
  await loadSubcollections(selectedStudentId);
}

async function updateNotification(notificationId, read) {
  if (!selectedStudentId) return;
  await api(`/students/${selectedStudentId}/notifications/${notificationId}`, {
    method: "PATCH",
    body: JSON.stringify({ read }),
  });
  showStatus(read ? "Marked as read." : "Marked as unread.");
  await loadSubcollections(selectedStudentId);
}

async function deleteNotification(notificationId) {
  if (!selectedStudentId) return;
  await api(`/students/${selectedStudentId}/notifications/${notificationId}`, { method: "DELETE" });
  showStatus("Notification deleted.");
  await loadSubcollections(selectedStudentId);
}

async function addDocument(event) {
  event.preventDefault();
  if (!selectedStudentId) return;

  const fileUrl = els.documentFileUrl.value.trim();
  const payload = {
    docType: els.documentType.value,
    status: els.documentStatus.value,
    fileUrl: fileUrl || null,
  };

  await api(`/students/${selectedStudentId}/documents`, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  els.documentForm.reset();
  showStatus("Document record added.");
  await loadSubcollections(selectedStudentId);
}

async function deleteDocument(documentId) {
  if (!selectedStudentId) return;
  await api(`/students/${selectedStudentId}/documents/${documentId}`, { method: "DELETE" });
  showStatus("Document deleted.");
  await loadSubcollections(selectedStudentId);
}

function showView(name) {
  const dashboard = name === "dashboard";
  els.viewDashboard.classList.toggle("hidden", !dashboard);
  els.viewStudents.classList.toggle("hidden", dashboard);
  document.querySelectorAll(".nav-btn").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === name);
  });
  els.pageKicker.textContent = dashboard ? "Overview" : "Records";
  els.pageTitle.textContent = dashboard ? "Cohort dashboard" : "Students";
  if (dashboard) loadDashboard().catch(handleError);
}

function syncThemeLabel() {
  const dark = document.documentElement.dataset.theme === "dark";
  els.themeLabel.textContent = dark ? "Light mode" : "Dark mode";
}

function bindEvents() {
  els.applyFilterBtn.addEventListener("click", () => loadStudents().catch(handleError));
  els.newStudentBtn.addEventListener("click", startNewStudent);
  els.saveStudentBtn.addEventListener("click", () => saveStudent().catch(handleError));
  els.deleteStudentBtn.addEventListener("click", () => deleteStudent().catch(handleError));
  els.courseForm.addEventListener("submit", (event) => addCourse(event).catch(handleError));
  els.notificationForm.addEventListener("submit", (event) => addNotification(event).catch(handleError));
  els.documentForm.addEventListener("submit", (event) => addDocument(event).catch(handleError));
  els.closeToastBtn.addEventListener("click", hideToast);
  els.dismissToastBtn.addEventListener("click", hideToast);
  els.toastBackdrop.addEventListener("click", hideToast);
  els.studentSearch.addEventListener("input", () => {
    searchQuery = els.studentSearch.value;
    renderStudentList();
  });
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", () => showTab(tab.dataset.tab));
  });
  document.querySelectorAll(".nav-btn").forEach((button) => {
    button.addEventListener("click", () => showView(button.dataset.view));
  });
  els.themeToggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    localStorage.setItem("aicc-theme", next);
    syncThemeLabel();
    document.dispatchEvent(new Event("aicc-theme"));
  });
  els.collapseToggle.addEventListener("click", () => {
    document.body.classList.toggle("sidebar-collapsed");
    localStorage.setItem(
      "aicc-sidebar",
      document.body.classList.contains("sidebar-collapsed") ? "collapsed" : "open"
    );
  });
  els.confirmModal.addEventListener("click", (event) => {
    if (event.target === els.confirmModal) els.confirmCancel.click();
  });
}

function handleError(error) {
  showStatus(error.message || "Something went wrong", "error");
}

async function init() {
  bindEvents();
  syncThemeLabel();
  catalog = await api("/catalog");
  populateCatalogDropdowns();
  await Promise.all([loadStudents(), loadDashboard()]);
}

init().catch(handleError);
