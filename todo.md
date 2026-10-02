# todo

## Routine (monthly, or after changing GNOME/input settings)

- [ ] `bash autobackup.sh` to re-dump dconf shell + desktop settings
- [ ] `git diff desktop/` and read what changed before committing
- [ ] re-export chewing vocabulary to `desktop/chewing/chewing.json` (gitignored); `autobackup.sh` encrypts it to `chewing.json.gpg` (passphrase in password manager)
- [ ] new GNOME extension installed? add its extensions.gnome.org ID to `GNOME_EXTENSIONS` in `setup_gui.sh`
- [ ] new apt package for the desktop? add it to `APT_PACKAGES` in `setup_gui.sh`
- [ ] `git status`, commit and push anything left uncommitted

## Backlog (found 2026-10-03)

- [x] last commit is 2026-07-08; dconf dumps last updated 2026-06-17
- [x] uncommitted: `claude/.claude/settings.json` (+37 lines), `git/.gitconfig` (+3 lines)
- [x] live dconf has drifted from the repo dumps: 14 changed lines under `/org/gnome/shell/`, 20 under `/org/gnome/desktop/` (Space Bar and switcher options, favorite-apps now has `com.microsoft.VSCode.desktop` instead of `code.desktop`, enabled-extensions now has `kimpanel@kde.org`)
- [x] add Kimpanel (`kimpanel@kde.org`, ID 261) to `GNOME_EXTENSIONS`; it fixes the fcitx5 chewing candidate window showing up on the other monitor under Wayland
- [ ] fcitx5 config is not in the repo: `~/.config/fcitx5/{config,profile,conf/}`; decide whether to stow it
- [x] `ibus-tweaker@tuberry.github.com` is still enabled although input is fcitx5 now; keep or drop
- [x] `GNOME_EXTENSIONS` lacks `ibus-tweaker` and `windowIsReady_Remover`, which are enabled in dconf; a fresh machine enables them in dconf but never installs them
- [x] bug in `autobackup.sh`: the `/history=/d` sed filter also deletes `clear-history=` (the Clipboard History shortcut, `<Control><Super>c`); anchor it, e.g. `/^history=/d`
- [ ] `autobackup.sh` ends at the comment "check and then git add/commit/push if everthing is ok"; nothing runs it on a schedule
