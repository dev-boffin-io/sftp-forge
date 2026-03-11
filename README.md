# SFTP Forge

A lightweight desktop GUI for managing SSH/SFTP connections on Linux.  
Built with Python and PyQt6.

---

## Features

- Save and manage multiple SSH/SFTP connection profiles
- Open SFTP in your file manager via `xdg-open sftp://…`
- Open an SSH terminal session directly from the GUI
- Mount remote filesystems locally using `sshfs`
- SSH key file support with a file browser
- Custom remote path per profile
- Profiles stored in `~/.config/sftp-forge.json`
- Auto-detects available terminal emulator and file manager
- Dark theme UI (GitHub Dark inspired)

---

## Requirements

| Dependency | Required | Notes |
|---|---|---|
| Python 3.10+ | Yes | Uses `str \| None` union syntax |
| PyQt6 | Yes | `pip install PyQt6` |
| ssh | Yes | Usually pre-installed |
| xdg-open | For SFTP | Part of `xdg-utils` |
| sshfs | For mounting | `apt install sshfs` |

### Supported terminal emulators

`gnome-terminal`, `konsole`, `xfce4-terminal`, `lxterminal`, `xterm`,
`x-terminal-emulator` (resolved via symlink at runtime)

### Supported file managers

`nautilus`, `dolphin`, `thunar`, `pcmanfm`, `nemo`

---

## Installation

```bash
# Clone the repository
git clone https://github.com/yourname/sftp-forge.git
cd sftp-forge

# Install Python dependency
pip install PyQt6

# Run
python3 sftp-forge.py
```

No build step required. Single-file application.

---

## Usage

1. Fill in the connection fields on the right panel
2. Click **Save Profile** to store the connection
3. Click a saved profile on the left to load it
4. Use the action buttons:

| Button | Action |
|---|---|
| Open SFTP | Opens the remote path in your file manager |
| Open Terminal | Opens an SSH session in your terminal |
| Mount (sshfs) | Mounts the remote path to `~/sftp_mount_<host>` |
| Save Profile | Saves the current form as a named profile |
| Delete Profile | Deletes the selected profile |

---

## Profile storage

Profiles are stored at:

```
~/.config/sftp-forge.json
```

Example entry:

```json
{
  "my-server": {
    "user": "ubuntu",
    "host": "192.168.1.100",
    "port": 22,
    "key": "/home/user/.ssh/id_rsa",
    "path": "/home/ubuntu"
  }
}
```

---

## Project structure

```
sftp-forge/
├── sftp-forge.py   # Main application (single file)
├── LICENSE
└── README.md
```

---

## License

MIT — see [LICENSE](LICENSE) for details.
