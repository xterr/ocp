# assets/ocp-demo.tape
Output assets/ocp-demo.gif

Set FontSize 16
Set Width 1280
Set Height 720
Set Padding 24
Set Theme { "name": "GitHub Dark", "background": "#0d1117", "foreground": "#c9d1d9", "cursor": "#c9d1d9", "selection": "#1f6feb", "black": "#484f58", "red": "#ff7b72", "green": "#3fb950", "yellow": "#d29922", "blue": "#58a6ff", "magenta": "#bc8cff", "cyan": "#39c5cf", "white": "#b1bac4", "brightBlack": "#6e7681", "brightRed": "#ffa198", "brightGreen": "#56d364", "brightYellow": "#e3b341", "brightBlue": "#79c0ff", "brightMagenta": "#d2a8ff", "brightCyan": "#56d4dd", "brightWhite": "#f0f6fc" }
Set TypingSpeed 55ms

Type "# Two isolated profiles, each with its own opencode account"
Enter
Sleep 800ms
Type "ocp list"
Enter
Sleep 2s

Type "cd ~/projects/work-project"
Enter
Sleep 500ms
Type "ocp current        # auto-detected from .ocprofile"
Enter
Sleep 2s
Type "opencode --pure    # launches under the WORK account"
Enter
Sleep 5s
Type "/exit"
Enter
Sleep 1500ms

Type "cd ~/projects/side-project"
Enter
Sleep 500ms
Type "ocp current        # different directory, different profile"
Enter
Sleep 2s
Type "opencode --pure    # PERSONAL account, separate sessions"
Enter
Sleep 5s
