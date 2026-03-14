#!/usr/bin/env python3

import sys
import os
import re
import json
import subprocess
import shutil

from PyQt6.QtWidgets import (
    QApplication, QWidget, QListWidget, QListWidgetItem,
    QLineEdit, QLabel, QPushButton, QVBoxLayout, QHBoxLayout,
    QGridLayout, QFileDialog, QMessageBox, QFrame, QSizePolicy,
    QCheckBox,
)
from PyQt6.QtCore import QThread, pyqtSignal, Qt


# ─────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────

CONFIG_PATH = os.path.expanduser("~/.config/sftp-forge.json")

FILE_MANAGERS = ["nautilus", "dolphin", "thunar", "pcmanfm", "nemo"]

TERMINALS = [
    "x-terminal-emulator",
    "gnome-terminal",
    "konsole",
    "xfce4-terminal",
    "lxterminal",
    "xterm",
]

DOUBLE_DASH_TERMINALS = {"gnome-terminal"}
STRING_ARG_TERMINALS  = {"xterm", "lxterminal", "xfce4-terminal", "xfce4-terminal.wrapper"}


# ─────────────────────────────────────────────
# Stylesheet  (GitHub-dark inspired)
# ─────────────────────────────────────────────

STYLESHEET = """
/* ── Global ─────────────────────────────── */
QWidget {
    background-color: #0d1117;
    color: #c9d1d9;
    font-family: "JetBrains Mono", "Fira Code", "Cascadia Code", monospace;
    font-size: 30px;
}

/* ── Sidebar ─────────────────────────────── */
QFrame#Sidebar {
    background-color: #161b22;
    border: none;
    border-right: 1px solid #21262d;
}

/* ── Right panel ─────────────────────────── */
QFrame#RightPanel {
    background-color: #0d1117;
    border: none;
}

/* ── Form card ───────────────────────────── */
QFrame#FormCard {
    background-color: #161b22;
    border: 1px solid #21262d;
    border-radius: 10px;
}

/* ── Labels ──────────────────────────────── */
QLabel#AppTitle {
    color: #e6edf3;
    font-size: 28px;
    font-weight: bold;
    letter-spacing: 1px;
}
QLabel#AppSubtitle {
    color: #3fb950;
    font-size: 26px;
    letter-spacing: 3px;
}
QLabel#SectionHeader {
    color: #8b949e;
    font-size: 24px;
    font-weight: bold;
    letter-spacing: 2px;
}
QLabel#FormLabel {
    color: #8b949e;
    font-size: 26px;
    font-weight: bold;
    letter-spacing: 0.5px;
    min-width: 120px;
}
QLabel#StatusLabel {
    color: #484f58;
    font-size: 18px;
    line-height: 1.5;
}

/* ── Divider ─────────────────────────────── */
QFrame#Divider {
    background-color: #21262d;
    border: none;
    max-height: 1px;
    min-height: 1px;
}

/* ── Profile list ────────────────────────── */
QListWidget {
    background-color: #0d1117;
    border: 1px solid #21262d;
    border-radius: 8px;
    padding: 4px;
    outline: none;
}
QListWidget::item {
    padding: 10px 12px;
    border-radius: 6px;
    margin: 1px 0;
    color: #c9d1d9;
    border-left: 3px solid transparent;
}
QListWidget::item:hover {
    background-color: #1c2128;
    border-left: 3px solid #30363d;
}
QListWidget::item:selected {
    background-color: #1a3a4a;
    color: #58a6ff;
    border-left: 3px solid #58a6ff;
}

/* ── Input fields ────────────────────────── */
QLineEdit {
    background-color: #0d1117;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 9px 14px;
    color: #e6edf3;
    selection-background-color: #1f6feb;
    font-size: 30px;
    min-height: 24px;
}
QLineEdit:focus {
    border: 1px solid #58a6ff;
    background-color: #0d1117;
}
QLineEdit:hover {
    border: 1px solid #484f58;
}

/* ── Buttons: default ────────────────────── */
QPushButton {
    background-color: #21262d;
    color: #c9d1d9;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 6px 22px;
    font-size: 28px;
    font-weight: bold;
    min-height: 22px;
}
QPushButton:hover {
    background-color: #30363d;
    border-color: #8b949e;
    color: #e6edf3;
}
QPushButton:pressed {
    background-color: #161b22;
    border-color: #58a6ff;
}
QPushButton:disabled {
    background-color: #161b22;
    color: #484f58;
    border-color: #21262d;
}

/* ── Accent (blue) ───────────────────────── */
QPushButton#AccentBtn {
    background-color: #1f6feb;
    color: #ffffff;
    border: 1px solid #388bfd;
}
QPushButton#AccentBtn:hover {
    background-color: #388bfd;
    border-color: #58a6ff;
}
QPushButton#AccentBtn:pressed {
    background-color: #1158c7;
}

/* ── Green ───────────────────────────────── */
QPushButton#GreenBtn {
    background-color: #1a4731;
    color: #3fb950;
    border: 1px solid #2ea043;
}
QPushButton#GreenBtn:hover {
    background-color: #2ea043;
    color: #ffffff;
    border-color: #3fb950;
}
QPushButton#GreenBtn:pressed {
    background-color: #196027;
}
QPushButton#GreenBtn:disabled {
    background-color: #161b22;
    color: #484f58;
    border-color: #21262d;
}

/* ── Danger (red) ────────────────────────── */
QPushButton#DangerBtn {
    background-color: #160e0e;
    color: #f85149;
    border: 1px solid #6e1c1c;
}
QPushButton#DangerBtn:hover {
    background-color: #6e1c1c;
    color: #ffa198;
    border-color: #f85149;
}
QPushButton#DangerBtn:pressed {
    background-color: #490c0c;
}

/* ── Raw mode checkbox ───────────────────── */
QCheckBox#RawToggle {
    color: #8b949e;
    font-size: 24px;
    spacing: 10px;
}
QCheckBox#RawToggle::indicator {
    width: 26px;
    height: 26px;
    border-radius: 5px;
    border: 2px solid #30363d;
    background-color: #0d1117;
}
QCheckBox#RawToggle::indicator:checked {
    background-color: #1f6feb;
    border-color: #58a6ff;
}
QCheckBox#RawToggle::indicator:hover {
    border-color: #484f58;
}

/* ── Scrollbar ───────────────────────────── */
QScrollBar:vertical {
    background: #0d1117;
    width: 7px;
    border-radius: 4px;
}
QScrollBar::handle:vertical {
    background: #30363d;
    border-radius: 4px;
    min-height: 20px;
}
QScrollBar::handle:vertical:hover {
    background: #484f58;
}
QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical {
    height: 0;
}
"""


# ─────────────────────────────────────────────
# System detection
# ─────────────────────────────────────────────

def detect_first(candidates: list[str]) -> str | None:
    for c in candidates:
        if shutil.which(c):
            return c
    return None

def has_sshfs() -> bool:
    return shutil.which("sshfs") is not None

def has_xdg_open() -> bool:
    return shutil.which("xdg-open") is not None


# ─────────────────────────────────────────────
# SSH helpers
# ─────────────────────────────────────────────

def build_ssh_cmd(target: str, port: int, key: str | None) -> list[str]:
    cmd = ["ssh", "-p", str(port)]
    if key:
        cmd += ["-i", key]
    cmd.append(target)
    return cmd

def _resolve_terminal_binary(terminal: str) -> str:
    """Follow x-terminal-emulator symlink to find the real binary name."""
    try:
        real = shutil.which(terminal)
        if real:
            real = os.path.realpath(real)
            return os.path.basename(real).lower()
    except Exception:
        pass
    return terminal


def wrap_in_terminal(terminal: str, ssh_cmd: list[str]) -> list[str]:
    """
    Wrap ssh_cmd in the given terminal emulator.
    - gnome-terminal          -> terminal -- ssh ...
    - xfce4-terminal / xterm
      / lxterminal            -> terminal -e "ssh ..."  (single string)
    - konsole / others        -> terminal -e ssh ...    (arg list)
    x-terminal-emulator symlink is resolved at runtime to pick the right style.
    """
    effective = terminal
    if terminal == "x-terminal-emulator":
        effective = _resolve_terminal_binary(terminal)

    if effective in DOUBLE_DASH_TERMINALS:
        return [terminal, "--"] + ssh_cmd

    if effective in STRING_ARG_TERMINALS:
        return [terminal, "-e", " ".join(ssh_cmd)]

    # konsole, mate-terminal, tilix, etc.
    return [terminal, "-e"] + ssh_cmd


# ─────────────────────────────────────────────
# Background worker
# ─────────────────────────────────────────────

class MountWorker(QThread):
    success = pyqtSignal(str)
    failure = pyqtSignal(str)

    def __init__(self, cmd: list[str], mount_dir: str):
        super().__init__()
        self.cmd = cmd
        self.mount_dir = mount_dir
        # Auto-delete the Qt object once the thread finishes,
        # but only after the event loop has processed the signals.
        self.finished.connect(self.deleteLater)

    def run(self):
        try:
            result = subprocess.run(self.cmd, capture_output=True, text=True)
            if result.returncode != 0:
                self.failure.emit(result.stderr.strip() or "sshfs exited with error")
            else:
                self.success.emit(self.mount_dir)
        except Exception as exc:
            self.failure.emit(str(exc))


# ─────────────────────────────────────────────
# Profile store
# ─────────────────────────────────────────────

class ProfileStore:
    def __init__(self, path: str = CONFIG_PATH):
        self.path = path
        self._data: dict = {}
        self.load()

    def load(self):
        if os.path.exists(self.path):
            try:
                with open(self.path) as f:
                    self._data = json.load(f)
            except Exception:
                self._data = {}
        else:
            self._data = {}

    def save(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with open(self.path, "w") as f:
            json.dump(self._data, f, indent=2)

    def names(self) -> list[str]:
        return sorted(self._data.keys())

    def get(self, name: str) -> dict | None:
        return self._data.get(name)

    def set(self, name: str, data: dict):
        self._data[name] = data
        self.save()

    def delete(self, name: str):
        if name in self._data:
            del self._data[name]
            self.save()


# ─────────────────────────────────────────────
# Widget factories
# ─────────────────────────────────────────────

def app_title(text: str) -> QLabel:
    lbl = QLabel(text)
    lbl.setObjectName("AppTitle")
    return lbl

def section_lbl(text: str) -> QLabel:
    lbl = QLabel(text)
    lbl.setObjectName("SectionHeader")
    return lbl

def form_lbl(text: str) -> QLabel:
    lbl = QLabel(text)
    lbl.setObjectName("FormLabel")
    return lbl

def divider() -> QFrame:
    f = QFrame()
    f.setObjectName("Divider")
    f.setFrameShape(QFrame.Shape.HLine)
    return f

def btn(text: str, style: str = "") -> QPushButton:
    b = QPushButton(text)
    if style == "accent":
        b.setObjectName("AccentBtn")
    elif style == "green":
        b.setObjectName("GreenBtn")
    elif style == "danger":
        b.setObjectName("DangerBtn")
    return b


# ─────────────────────────────────────────────
# Main window
# ─────────────────────────────────────────────

class SFTPForge(QWidget):

    def __init__(self):
        super().__init__()
        self.setWindowTitle("SFTP Forge")
        # sized in _fit_to_screen() after screen geometry is known

        self.store        = ProfileStore()
        self.file_manager = detect_first(FILE_MANAGERS)
        self.terminal     = detect_first(TERMINALS)
        self.sshfs_ok     = has_sshfs()
        self.xdg_ok       = has_xdg_open()
        self._mount_worker: MountWorker | None = None

        self._init_ui()
        self._refresh_list()
        self._fit_to_screen()

    # ── Root layout ───────────────────────────


    def _fit_to_screen(self):
        screen = QApplication.primaryScreen().availableGeometry()
        w = min(1500, int(screen.width() * 0.92))
        h = min(620,  int(screen.height() * 0.82))
        self.setMinimumSize(min(1100, w), min(500, h))
        self.resize(w, h)
        # Center on screen
        x = screen.x() + (screen.width()  - w) // 2
        y = screen.y() + (screen.height() - h) // 2
        self.move(x, y)

    def _init_ui(self):
        root = QHBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)
        root.addWidget(self._build_sidebar())
        root.addWidget(self._build_right(), stretch=1)

    # ── Sidebar ───────────────────────────────

    def _build_sidebar(self) -> QFrame:
        sidebar = QFrame()
        sidebar.setObjectName("Sidebar")
        sidebar.setMinimumWidth(280)
        sidebar.setMaximumWidth(340)

        lay = QVBoxLayout(sidebar)
        lay.setContentsMargins(16, 20, 16, 16)
        lay.setSpacing(0)

        # Branding
        lay.addWidget(app_title("SFTP Forge"))
        sub = QLabel("SSH  SFTP  SSHFS")
        sub.setObjectName("AppSubtitle")
        lay.addWidget(sub)
        lay.addSpacing(14)
        lay.addWidget(divider())
        lay.addSpacing(14)

        lay.addWidget(section_lbl("SAVED PROFILES"))
        lay.addSpacing(8)

        self.profile_list = QListWidget()
        self.profile_list.itemClicked.connect(self._on_profile_clicked)
        self.profile_list.setSizePolicy(
            QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding
        )
        lay.addWidget(self.profile_list)

        lay.addSpacing(12)

        # Detected tools info
        term_txt = self.terminal or "not found"
        fm_txt   = self.file_manager or "not found"
        info = QLabel(f"terminal: {term_txt}\nfile mgr:  {fm_txt}")
        info.setObjectName("StatusLabel")
        lay.addWidget(info)

        lay.addSpacing(10)

        del_b = btn("Delete Profile", "danger")
        del_b.clicked.connect(self._delete_profile)
        del_b.setMinimumHeight(50)
        lay.addWidget(del_b)

        return sidebar

    # ── Right panel ───────────────────────────

    def _build_right(self) -> QFrame:
        panel = QFrame()
        panel.setObjectName("RightPanel")

        lay = QVBoxLayout(panel)
        lay.setContentsMargins(28, 24, 28, 20)
        lay.setSpacing(0)

        # Page heading
        lay.addWidget(app_title("Connection Profile"))
        lay.addSpacing(14)
        lay.addWidget(divider())
        lay.addSpacing(18)

        # ── Form card ──
        card = QFrame()
        card.setObjectName("FormCard")
        grid = QGridLayout(card)
        grid.setContentsMargins(22, 18, 22, 18)
        grid.setHorizontalSpacing(14)
        grid.setVerticalSpacing(13)
        grid.setColumnStretch(1, 1)

        self.f_name = QLineEdit(); self.f_name.setPlaceholderText("e.g. prod-server")
        self.f_user = QLineEdit(); self.f_user.setPlaceholderText("e.g. ubuntu")
        self.f_host = QLineEdit(); self.f_host.setPlaceholderText("192.168.1.100 or example.com")
        self.f_port = QLineEdit("22"); self.f_port.setMaximumWidth(120)
        self.f_key  = QLineEdit(); self.f_key.setPlaceholderText("~/.ssh/id_rsa  (blank = password auth)")
        self.f_path = QLineEdit("/"); self.f_path.setPlaceholderText("/home/user")

        fields = [
            ("Profile Name",  self.f_name, None),
            ("Username",      self.f_user, None),
            ("Host / IP",     self.f_host, None),
            ("Port",          self.f_port, None),
            ("SSH Key Path",  self.f_key,  self._browse_key),
            ("Remote Path",   self.f_path, None),
        ]

        for i, (label, widget, slot) in enumerate(fields):
            grid.addWidget(form_lbl(label), i, 0, Qt.AlignmentFlag.AlignVCenter)
            grid.addWidget(widget, i, 1)
            if slot:
                browse_b = btn("Browse")
                browse_b.setFixedWidth(120)
                browse_b.setMinimumHeight(50)
                browse_b.clicked.connect(slot)
                grid.addWidget(browse_b, i, 2)

        lay.addWidget(card)
        lay.addSpacing(20)
        lay.addWidget(divider())
        lay.addSpacing(16)

        # ── Action buttons ──
        btn_row = QHBoxLayout()
        btn_row.setSpacing(10)

        sftp_b = btn("Open SFTP", "accent")
        sftp_b.setToolTip("xdg-open sftp://…")
        sftp_b.clicked.connect(self._open_sftp)

        term_b = btn("Open Terminal", "accent")
        term_b.setToolTip("SSH session in terminal")
        term_b.clicked.connect(self._open_terminal)

        self.mount_btn = btn("Mount (sshfs)", "green")
        self.mount_btn.clicked.connect(self._mount_sshfs)
        if not self.sshfs_ok:
            self.mount_btn.setEnabled(False)
            self.mount_btn.setToolTip("sshfs not found in PATH")

        save_b = btn("Save Profile", "green")
        save_b.clicked.connect(self._save_profile)

        for b in (sftp_b, term_b, self.mount_btn, save_b):
            b.setMinimumHeight(52)
            btn_row.addWidget(b)

        # Raw mode toggle — sits at the right end of the button row
        self.raw_toggle = QCheckBox("Raw mode")
        self.raw_toggle.setObjectName("RawToggle")
        self.raw_toggle.setToolTip(
            "Checked: run ssh / sftp directly in terminal\n"
            "Unchecked: open via xdg-open (file manager)"
        )
        self.raw_toggle.setMinimumHeight(52)
        btn_row.addWidget(self.raw_toggle)

        lay.addLayout(btn_row)
        lay.addStretch()

        return panel

    # ── Profile helpers ───────────────────────

    def _refresh_list(self):
        self.profile_list.clear()
        for name in self.store.names():
            self.profile_list.addItem(f"  {name}")

    def _on_profile_clicked(self, item):
        name = item.text().strip()
        p = self.store.get(name)
        if not p:
            return
        self.f_name.setText(name)
        self.f_user.setText(p.get("user", ""))
        self.f_host.setText(p.get("host", ""))
        self.f_port.setText(str(p.get("port", 22)))
        self.f_key.setText(p.get("key", ""))
        self.f_path.setText(p.get("path", "/"))

    def _delete_profile(self):
        item = self.profile_list.currentItem()
        if not item:
            QMessageBox.warning(self, "Delete", "No profile selected")
            return
        name = item.text().strip()
        reply = QMessageBox.question(
            self, "Delete Profile", f"Delete '{name}'?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.store.delete(name)
            self._refresh_list()

    # ── Form helpers ──────────────────────────

    def _browse_key(self):
        path, _ = QFileDialog.getOpenFileName(self, "Select SSH Key")
        if path:
            self.f_key.setText(path)

    def _read_form(self) -> dict | None:
        host = self.f_host.text().strip()
        if not host:
            QMessageBox.warning(self, "Validation", "Host is required")
            return None
        try:
            port = int(self.f_port.text().strip())
            if not (1 <= port <= 65535):
                raise ValueError
        except ValueError:
            QMessageBox.warning(self, "Validation", "Port must be 1–65535")
            return None
        return {
            "name": self.f_name.text().strip(),
            "user": self.f_user.text().strip(),
            "host": host,
            "port": port,
            "key":  self.f_key.text().strip(),
            "path": self._sanitize_path(self.f_path.text().strip()),
        }

    @staticmethod
    def _sanitize_path(path: str) -> str:
        return os.path.normpath("/" + path) if path else "/"

    def _target(self, form: dict) -> str:
        u = form["user"]
        return f"{u}@{form['host']}" if u else form["host"]

    def _key_ok(self, form: dict) -> bool:
        if form["key"] and not os.path.exists(form["key"]):
            QMessageBox.warning(self, "Error", f"SSH key not found:\n{form['key']}")
            return False
        return True

    # ── Actions ───────────────────────────────

    def _save_profile(self):
        form = self._read_form()
        if not form:
            return
        if not form["name"]:
            QMessageBox.warning(self, "Validation", "Profile name is required")
            return
        self.store.set(form["name"], {k: v for k, v in form.items() if k != "name"})
        self._refresh_list()

    def _open_sftp(self):
        form = self._read_form()
        if not form or not self._key_ok(form):
            return
        if self.raw_toggle.isChecked():
            if not self.terminal:
                QMessageBox.warning(self, "Error", "No terminal emulator found")
                return
            cmd = ["sftp", "-P", str(form["port"])]
            if form["key"]:
                cmd += ["-i", form["key"]]
            cmd.append(self._target(form))
            subprocess.Popen(wrap_in_terminal(self.terminal, cmd), close_fds=True)
        else:
            if not self.xdg_ok:
                QMessageBox.warning(self, "Error", "xdg-open not found")
                return
            port   = form["port"]
            target = self._target(form)
            path   = form["path"]
            if port == 22:
                url = f"sftp://{target}{path}"
            else:
                url = f"sftp://{target}:{port}{path}"
            subprocess.Popen(["xdg-open", url], close_fds=True)

    def _open_terminal(self):
        if not self.terminal:
            QMessageBox.warning(self, "Error", "No terminal emulator found")
            return
        form = self._read_form()
        if not form or not self._key_ok(form):
            return
        ssh = build_ssh_cmd(self._target(form), form["port"], form["key"] or None)
        cmd = wrap_in_terminal(self.terminal, ssh)
        subprocess.Popen(cmd, close_fds=True)

    def _mount_sshfs(self):
        if not self.sshfs_ok:
            QMessageBox.warning(self, "Unavailable", "sshfs not installed")
            return
        form = self._read_form()
        if not form or not self._key_ok(form):
            return

        safe = re.sub(r"[^a-zA-Z0-9_-]", "_", form["host"])
        mount_dir = os.path.expanduser(f"~/sftp_mount_{safe}")
        os.makedirs(mount_dir, exist_ok=True)

        cmd = ["sshfs", "-p", str(form["port"])]
        if form["key"]:
            cmd += ["-o", f"IdentityFile={form['key']}"]
        cmd += [f"{self._target(form)}:{form['path']}", mount_dir]

        self.mount_btn.setEnabled(False)
        self.mount_btn.setText("Mounting...")

        self._mount_worker = MountWorker(cmd, mount_dir)
        self._mount_worker.success.connect(self._on_mount_ok)
        self._mount_worker.failure.connect(self._on_mount_fail)
        # Drop our Python reference only after the thread has fully finished
        # so the QThread object is not garbage-collected while still running.
        self._mount_worker.finished.connect(self._on_worker_finished)
        self._mount_worker.start()

    def _on_mount_ok(self, mount_dir: str):
        self._reset_mount_btn()
        QMessageBox.information(self, "Mounted", f"Mounted at:\n{mount_dir}")
        if self.file_manager:
            subprocess.Popen([self.file_manager, mount_dir], close_fds=True)

    def _on_mount_fail(self, error: str):
        self._reset_mount_btn()
        QMessageBox.critical(self, "Mount failed", error)

    def _on_worker_finished(self):
        # Safe to drop the Python reference now — the thread has stopped.
        self._mount_worker = None

    def _reset_mount_btn(self):
        self.mount_btn.setEnabled(self.sshfs_ok)
        self.mount_btn.setText("Mount (sshfs)")


# ─────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────

def main():
    app = QApplication(sys.argv)
    app.setStyleSheet(STYLESHEET)
    win = SFTPForge()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
