import Foundation

extension RelayCommand {

    // MARK: - AI Pack

    static let aiPack: [RelayCommand] = [
        RelayCommand(
            name: "Start LM Studio",
            details: "Launch LM Studio and wait for the local API to be ready.",
            category: "AI",
            icon: "brain",
            tags: ["ai", "llm", "lmstudio"],
            aliases: ["lm", "start lm"],
            command: "open -a 'LM Studio' && sleep 5 && curl -s http://localhost:1234/v1/models | head -1",
            timeoutSeconds: 30,
            runInBackground: true,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Stop LM Studio",
            details: "Quit LM Studio.",
            category: "AI",
            icon: "brain.slash",
            tags: ["ai", "llm", "lmstudio"],
            aliases: ["stop lm"],
            command: "osascript -e 'quit app \"LM Studio\"'",
            timeoutSeconds: 10,
            runInBackground: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Restart Ollama",
            details: "Stop and restart the Ollama service.",
            category: "AI",
            icon: "arrow.clockwise.circle",
            tags: ["ai", "ollama", "llm"],
            aliases: ["restart ollama"],
            command: "brew services restart ollama",
            timeoutSeconds: 30,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Check AI Environment",
            details: "Verify Ollama, LM Studio API, and Python AI tools are available.",
            category: "AI",
            icon: "checklist",
            tags: ["ai", "ollama", "lmstudio", "check"],
            aliases: ["ai check", "ai env"],
            command: """
            echo "=== Ollama ===" && ollama list 2>/dev/null || echo "Ollama not running"
            echo "=== LM Studio API ===" && curl -s http://localhost:1234/v1/models | python3 -m json.tool 2>/dev/null || echo "LM Studio API not available"
            echo "=== Python AI packages ===" && pip3 list 2>/dev/null | grep -E "torch|mlx|transformers|openai" || echo "No packages found"
            """,
            timeoutSeconds: 20
        ),
        RelayCommand(
            name: "List Ollama Models",
            details: "Show all locally downloaded Ollama models.",
            category: "AI",
            icon: "list.bullet",
            tags: ["ai", "ollama", "models"],
            aliases: ["ollama list", "models"],
            command: "ollama list",
            timeoutSeconds: 10,
            favorite: true
        ),
        RelayCommand(
            name: "Pull Ollama Model",
            details: "Pull a model from the Ollama registry (e.g. llama3, mistral).",
            category: "AI",
            icon: "arrow.down.circle",
            tags: ["ai", "ollama", "models", "pull"],
            aliases: ["ollama pull"],
            command: "ollama pull llama3",
            timeoutSeconds: 600,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Open LM Studio API Docs",
            details: "Open the local LM Studio OpenAI-compatible API in the browser.",
            category: "AI",
            icon: "globe",
            tags: ["ai", "lmstudio", "api", "docs"],
            aliases: ["lm api"],
            command: "open http://localhost:1234",
            timeoutSeconds: 5,
            runInBackground: true
        ),
    ]

    // MARK: - Git Pack

    static let gitPack: [RelayCommand] = [
        RelayCommand(
            name: "Git Status",
            details: "Show working tree status.",
            category: "Development",
            icon: "arrow.triangle.branch",
            tags: ["git", "dev", "vcs"],
            aliases: ["gs"],
            workingDirectory: "$CurrentProject",
            command: "git status",
            timeoutSeconds: 15,
            favorite: true
        ),
        RelayCommand(
            name: "Pull Repository",
            details: "Fetch and merge latest changes from origin.",
            category: "Development",
            icon: "arrow.down.to.line",
            tags: ["git", "dev", "pull"],
            aliases: ["git pull", "pull"],
            workingDirectory: "$CurrentProject",
            command: "git pull --rebase origin HEAD",
            timeoutSeconds: 60,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Git Log",
            details: "Show recent commit history with one-line summaries.",
            category: "Development",
            icon: "clock.arrow.circlepath",
            tags: ["git", "dev", "log"],
            aliases: ["git log", "glog"],
            workingDirectory: "$CurrentProject",
            command: "git log --oneline --graph --decorate -20",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Git Branch",
            details: "List all local and remote branches.",
            category: "Development",
            icon: "arrow.triangle.branch",
            tags: ["git", "dev", "branch"],
            aliases: ["git branch", "gb"],
            workingDirectory: "$CurrentProject",
            command: "git branch -a",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Git Stash",
            details: "Stash uncommitted changes.",
            category: "Development",
            icon: "tray.and.arrow.down",
            tags: ["git", "dev", "stash"],
            aliases: ["git stash"],
            workingDirectory: "$CurrentProject",
            command: "git stash push -m \"Relay stash $(date '+%Y-%m-%d %H:%M')\"",
            timeoutSeconds: 15,
            requiresConfirmation: true
        ),
        RelayCommand(
            name: "Git Stash Pop",
            details: "Restore the most recent stash.",
            category: "Development",
            icon: "tray.and.arrow.up",
            tags: ["git", "dev", "stash"],
            aliases: ["stash pop"],
            workingDirectory: "$CurrentProject",
            command: "git stash pop",
            timeoutSeconds: 15,
            requiresConfirmation: true
        ),
        RelayCommand(
            name: "Open in VS Code",
            details: "Open the current project in Visual Studio Code.",
            category: "Development",
            icon: "curlybraces",
            tags: ["vscode", "editor", "dev"],
            aliases: ["code", "vscode"],
            workingDirectory: "$CurrentProject",
            command: "code $CurrentProject",
            timeoutSeconds: 10,
            runInBackground: true,
            favorite: true
        ),
        RelayCommand(
            name: "Run Tests",
            details: "Run the project test suite.",
            category: "Development",
            icon: "checkmark.circle",
            tags: ["test", "dev", "xcode", "swift"],
            aliases: ["test", "run tests"],
            workingDirectory: "$CurrentProject",
            command: "swift test 2>&1 | tail -30",
            timeoutSeconds: 300,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Build Project",
            details: "Build the Swift/Xcode project in release mode.",
            category: "Development",
            icon: "hammer",
            tags: ["build", "dev", "swift", "xcode"],
            aliases: ["build", "swift build"],
            workingDirectory: "$CurrentProject",
            command: "swift build -c release 2>&1 | tail -30",
            timeoutSeconds: 300,
            notifyOnCompletion: true
        ),
    ]

    // MARK: - Docker Pack

    static let dockerPack: [RelayCommand] = [
        RelayCommand(
            name: "Docker PS",
            details: "List all running containers.",
            category: "Docker",
            icon: "shippingbox",
            tags: ["docker", "containers", "dev"],
            aliases: ["docker ps", "containers"],
            command: "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'",
            timeoutSeconds: 10,
            favorite: true
        ),
        RelayCommand(
            name: "Docker Compose Up",
            details: "Start all services defined in docker-compose.yml.",
            category: "Docker",
            icon: "play.circle",
            tags: ["docker", "compose", "dev"],
            aliases: ["docker up", "compose up"],
            workingDirectory: "$CurrentProject",
            command: "docker compose up -d",
            timeoutSeconds: 120,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Docker Compose Down",
            details: "Stop and remove all compose services.",
            category: "Docker",
            icon: "stop.circle",
            tags: ["docker", "compose", "dev"],
            aliases: ["docker down", "compose down"],
            workingDirectory: "$CurrentProject",
            command: "docker compose down",
            timeoutSeconds: 60,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Docker Logs",
            details: "Tail logs from all running containers.",
            category: "Docker",
            icon: "doc.text",
            tags: ["docker", "logs", "dev"],
            aliases: ["docker logs"],
            workingDirectory: "$CurrentProject",
            command: "docker compose logs --tail=50 --follow",
            timeoutSeconds: 0
        ),
        RelayCommand(
            name: "Docker Pull Latest",
            details: "Pull the latest images for all compose services.",
            category: "Docker",
            icon: "arrow.down.circle",
            tags: ["docker", "pull", "dev"],
            aliases: ["docker pull"],
            workingDirectory: "$CurrentProject",
            command: "docker compose pull",
            timeoutSeconds: 300,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Docker System Prune",
            details: "Remove stopped containers, dangling images, and unused networks.",
            category: "Docker",
            icon: "trash",
            tags: ["docker", "prune", "cleanup"],
            aliases: ["docker prune", "prune docker"],
            command: "docker system prune -f",
            timeoutSeconds: 120,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Docker Stats",
            details: "Real-time CPU and memory usage of all containers.",
            category: "Docker",
            icon: "chart.bar",
            tags: ["docker", "stats", "monitor"],
            aliases: ["docker stats"],
            command: "docker stats --no-stream --format 'table {{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}'",
            timeoutSeconds: 15
        ),
    ]

    // MARK: - MLX Pack

    static let mlxPack: [RelayCommand] = [
        RelayCommand(
            name: "Check MLX Environment",
            details: "Verify MLX installation, version, and Apple Silicon availability.",
            category: "MLX",
            icon: "cpu",
            tags: ["mlx", "ai", "apple silicon"],
            aliases: ["mlx check", "mlx env"],
            command: """
            python3 -c "import mlx.core as mx; print('MLX:', mx.__version__); print('Device:', mx.default_device())"
            """,
            timeoutSeconds: 15,
            favorite: true
        ),
        RelayCommand(
            name: "List MLX Models",
            details: "Show MLX models cached in the Hugging Face hub cache.",
            category: "MLX",
            icon: "list.bullet",
            tags: ["mlx", "ai", "models", "hf"],
            aliases: ["mlx models"],
            command: "find ~/.cache/huggingface -name 'config.json' -path '*/mlx*' | sed 's|/config.json||' | xargs -I{} basename {} 2>/dev/null || echo 'No MLX models cached'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Run MLX Benchmark",
            details: "Quick matrix multiplication benchmark to verify MLX performance.",
            category: "MLX",
            icon: "gauge.open.with.lines.needle.33percent",
            tags: ["mlx", "benchmark", "apple silicon"],
            aliases: ["mlx benchmark"],
            command: """
            python3 -c "
            import mlx.core as mx, time
            a = mx.random.normal((2048, 2048))
            b = mx.random.normal((2048, 2048))
            mx.eval(a, b)
            t = time.perf_counter()
            for _ in range(10): c = a @ b
            mx.eval(c)
            print(f'2048x2048 matmul x10: {(time.perf_counter()-t)*1000:.1f} ms')
            "
            """,
            timeoutSeconds: 30
        ),
        RelayCommand(
            name: "Install MLX",
            details: "Install or upgrade the MLX package via pip.",
            category: "MLX",
            icon: "arrow.down.circle",
            tags: ["mlx", "install", "pip"],
            aliases: ["pip install mlx"],
            command: "pip3 install -U mlx mlx-lm",
            timeoutSeconds: 120,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Run MLX Chat",
            details: "Start an interactive chat with a local MLX language model.",
            category: "MLX",
            icon: "bubble.left.and.bubble.right",
            tags: ["mlx", "chat", "llm"],
            aliases: ["mlx chat"],
            command: "python3 -m mlx_lm.generate --model mlx-community/Mistral-7B-Instruct-v0.3-4bit --max-tokens 500 --prompt 'Hello!'",
            timeoutSeconds: 120,
            notifyOnCompletion: true
        ),
    ]

    // MARK: - LM Studio Pack

    static let lmStudioPack: [RelayCommand] = [
        RelayCommand(
            name: "Open LM Studio",
            details: "Launch the LM Studio desktop app.",
            category: "LM Studio",
            icon: "brain",
            tags: ["lmstudio", "ai"],
            aliases: ["open lm"],
            command: "open -a 'LM Studio'",
            timeoutSeconds: 15,
            runInBackground: true,
            favorite: true
        ),
        RelayCommand(
            name: "LM Studio API Status",
            details: "Check whether the LM Studio local API server is running.",
            category: "LM Studio",
            icon: "antenna.radiowaves.left.and.right",
            tags: ["lmstudio", "api", "status"],
            aliases: ["lm status", "lm api status"],
            command: "curl -s --max-time 3 http://localhost:1234/v1/models | python3 -m json.tool || echo 'LM Studio API is not running on port 1234'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "List LM Studio Models",
            details: "Show models loaded in the LM Studio API.",
            category: "LM Studio",
            icon: "list.bullet",
            tags: ["lmstudio", "models", "api"],
            aliases: ["lm models"],
            command: "curl -s http://localhost:1234/v1/models | python3 -c \"import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]\" 2>/dev/null || echo 'API unavailable'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "LM Studio Quick Chat",
            details: "Send a test prompt to the LM Studio API and print the reply.",
            category: "LM Studio",
            icon: "bubble.left",
            tags: ["lmstudio", "api", "test"],
            aliases: ["lm chat", "lm test"],
            command: """
            curl -s http://localhost:1234/v1/chat/completions \
              -H "Content-Type: application/json" \
              -d '{"messages":[{"role":"user","content":"Say hello in one sentence."}],"max_tokens":60}' \
            | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"
            """,
            timeoutSeconds: 30
        ),
    ]

    // MARK: - Tailscale Pack

    static let tailscalePack: [RelayCommand] = [
        RelayCommand(
            name: "Tailscale Up",
            details: "Connect to the Tailscale network.",
            category: "Network",
            icon: "network.badge.shield.half.filled",
            tags: ["tailscale", "vpn", "network"],
            aliases: ["ts up"],
            command: "tailscale up",
            timeoutSeconds: 30,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Tailscale Down",
            details: "Disconnect from the Tailscale network.",
            category: "Network",
            icon: "network.slash",
            tags: ["tailscale", "vpn", "network"],
            aliases: ["ts down"],
            command: "tailscale down",
            timeoutSeconds: 15,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Tailscale Status",
            details: "Show Tailscale connection status and peer list.",
            category: "Network",
            icon: "network",
            tags: ["tailscale", "vpn", "network", "status"],
            aliases: ["ts status", "ts"],
            command: "tailscale status",
            timeoutSeconds: 20,
            favorite: true
        ),
        RelayCommand(
            name: "Tailscale IP",
            details: "Show this device's Tailscale IP address.",
            category: "Network",
            icon: "number",
            tags: ["tailscale", "vpn", "ip"],
            aliases: ["ts ip", "tailscale ip"],
            command: "tailscale ip -4",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Network Status",
            details: "Show active network interfaces and their IP addresses.",
            category: "Network",
            icon: "wifi",
            tags: ["network", "ip", "interface"],
            aliases: ["net status", "ifconfig"],
            command: "ifconfig | grep -E '^[a-z]|inet ' | grep -v '127.0.0.1'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Ping Gateway",
            details: "Ping the default network gateway to test connectivity.",
            category: "Network",
            icon: "dot.radiowaves.left.and.right",
            tags: ["network", "ping", "gateway"],
            aliases: ["ping gw"],
            command: "ping -c 4 $(route -n get default | awk '/gateway:/{print $2}')",
            timeoutSeconds: 15
        ),
    ]

    // MARK: - Homebrew Pack

    static let homebrewPack: [RelayCommand] = [
        RelayCommand(
            name: "Update Homebrew",
            details: "Fetch the latest Homebrew formulae and cask information.",
            category: "System",
            icon: "arrow.clockwise",
            tags: ["homebrew", "brew", "system"],
            aliases: ["brew update"],
            command: "brew update",
            timeoutSeconds: 120,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Brew Upgrade All",
            details: "Upgrade all installed Homebrew packages.",
            category: "System",
            icon: "arrow.up.circle",
            tags: ["homebrew", "brew", "upgrade", "system"],
            aliases: ["brew upgrade"],
            command: "brew update && brew upgrade",
            timeoutSeconds: 600,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Brew Cleanup",
            details: "Remove old versions and cached downloads.",
            category: "System",
            icon: "trash",
            tags: ["homebrew", "brew", "cleanup", "system"],
            aliases: ["brew clean"],
            command: "brew cleanup --prune=7",
            timeoutSeconds: 120,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Brew Doctor",
            details: "Run Homebrew diagnostics and report issues.",
            category: "System",
            icon: "stethoscope",
            tags: ["homebrew", "brew", "doctor", "diagnose"],
            aliases: ["brew doctor"],
            command: "brew doctor",
            timeoutSeconds: 60
        ),
        RelayCommand(
            name: "Brew List",
            details: "List all installed Homebrew formulae and casks.",
            category: "System",
            icon: "list.bullet",
            tags: ["homebrew", "brew", "list"],
            aliases: ["brew list"],
            command: "brew list --formula && echo '--- Casks ---' && brew list --cask",
            timeoutSeconds: 15
        ),
        RelayCommand(
            name: "Empty Caches",
            details: "Clear system and user caches to free disk space.",
            category: "System",
            icon: "memories.badge.minus",
            tags: ["cache", "cleanup", "system", "disk"],
            aliases: ["clear cache", "empty cache"],
            command: "rm -rf ~/Library/Caches/* && brew cleanup --prune=all",
            timeoutSeconds: 120,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
    ]

    // MARK: - Synology Pack

    static let synologyPack: [RelayCommand] = [
        RelayCommand(
            name: "Mount NAS",
            details: "Mount the Synology NAS share via SMB.",
            category: "Network",
            icon: "externaldrive.connected.to.line.below",
            tags: ["nas", "synology", "smb", "mount"],
            aliases: ["mount nas", "nas mount"],
            command: "mkdir -p $NAS && mount -t smbfs //guest@nas.local/shared $NAS",
            timeoutSeconds: 30,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Unmount NAS",
            details: "Safely unmount the Synology NAS share.",
            category: "Network",
            icon: "externaldrive.badge.xmark",
            tags: ["nas", "synology", "umount"],
            aliases: ["umount nas", "eject nas"],
            command: "diskutil unmount $NAS",
            timeoutSeconds: 15,
            requiresConfirmation: true,
            notifyOnCompletion: true
        ),
        RelayCommand(
            name: "Open Synology DSM",
            details: "Open the Synology DiskStation Manager web UI.",
            category: "Network",
            icon: "server.rack",
            tags: ["nas", "synology", "dsm", "web"],
            aliases: ["dsm", "open nas"],
            command: "open http://nas.local:5000",
            timeoutSeconds: 5,
            runInBackground: true
        ),
        RelayCommand(
            name: "NAS Disk Usage",
            details: "Show disk usage on the mounted NAS share.",
            category: "Network",
            icon: "chart.pie",
            tags: ["nas", "synology", "disk", "usage"],
            aliases: ["nas df"],
            command: "df -h $NAS",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Wake NAS",
            details: "Send a Wake-on-LAN magic packet to the Synology NAS.",
            category: "Network",
            icon: "bolt.circle",
            tags: ["nas", "synology", "wol", "wake"],
            aliases: ["wake nas", "wol"],
            command: "brew list wakeonlan &>/dev/null || brew install wakeonlan && wakeonlan -i nas.local FF:FF:FF:FF:FF:FF",
            timeoutSeconds: 15,
            notifyOnCompletion: true
        ),
    ]

    // MARK: - System Pack (core system utilities)

    static let systemPack: [RelayCommand] = [
        RelayCommand(
            name: "Flush DNS Cache",
            details: "Flush the macOS DNS resolver cache. Requires sudo.",
            category: "System",
            icon: "globe",
            tags: ["dns", "network", "system", "cache"],
            aliases: ["dns flush", "flush dns"],
            command: "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder",
            timeoutSeconds: 30,
            requiresConfirmation: true,
            requiresElevation: true,
            notifyOnCompletion: true,
            favorite: true
        ),
        RelayCommand(
            name: "Show Disk Usage",
            details: "Human-readable disk usage for all mounted volumes.",
            category: "System",
            icon: "internaldrive",
            tags: ["disk", "storage", "system"],
            aliases: ["df", "disk usage"],
            command: "df -h | grep -v 'devfs\\|map'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Top Processes",
            details: "Show the 15 most CPU-intensive processes.",
            category: "System",
            icon: "chart.bar.xaxis",
            tags: ["processes", "cpu", "system", "monitor"],
            aliases: ["top", "processes"],
            command: "ps aux | sort -rk 3 | head -16",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Memory Pressure",
            details: "Show current memory usage and pressure.",
            category: "System",
            icon: "memorychip",
            tags: ["memory", "ram", "system", "monitor"],
            aliases: ["mem", "ram"],
            command: "memory_pressure && vm_stat | perl -ne '/page size of (\\d+)/ and $size=$1; /Pages\\s+([^:]+)[^\\d]+(\\d+)/ and printf(\"%s: %.2f GB\\n\", $1, $2 * $size / 1e9)'",
            timeoutSeconds: 10
        ),
        RelayCommand(
            name: "Restart Dock",
            details: "Restart the macOS Dock process.",
            category: "System",
            icon: "dock.rectangle",
            tags: ["dock", "macos", "ui", "restart"],
            aliases: ["restart dock", "killall dock"],
            command: "killall Dock",
            timeoutSeconds: 5,
            runInBackground: true
        ),
        RelayCommand(
            name: "Restart Finder",
            details: "Restart the macOS Finder process.",
            category: "System",
            icon: "folder",
            tags: ["finder", "macos", "ui", "restart"],
            aliases: ["restart finder"],
            command: "killall Finder",
            timeoutSeconds: 5,
            runInBackground: true
        ),
        RelayCommand(
            name: "Screenshot to Desktop",
            details: "Take a full-screen screenshot and save to Desktop.",
            category: "System",
            icon: "camera",
            tags: ["screenshot", "macos"],
            aliases: ["screenshot", "capture"],
            command: "screencapture -x ~/Desktop/screenshot-$(date +%Y%m%d-%H%M%S).png",
            timeoutSeconds: 5,
            runInBackground: true,
            notifyOnCompletion: true
        ),
    ]

    // MARK: - Combined sample library

    /// Full set of sample commands seeded on first run.
    public static let samples: [RelayCommand] =
        aiPack + gitPack + dockerPack + mlxPack + lmStudioPack +
        tailscalePack + homebrewPack + synologyPack + systemPack
}
