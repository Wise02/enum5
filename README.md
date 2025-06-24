# enum5.sh - Subdomain Enumeration & Screenshot Automation

**Version:** 3.0

## Overview

`enum5.sh` is a powerful Bash script designed to automate the process of subdomain enumeration, live host detection, and screenshot capture for a given domain. It leverages industry-standard tools to provide comprehensive reconnaissance, making it an essential asset for bug bounty hunters, penetration testers, and security researchers.

## Features

- **Automated Subdomain Enumeration:** Uses Subfinder, Amass, Assetfinder, and Sublist3r for maximum coverage.
- **Live Host Detection:** Checks which subdomains are alive using Httprobe.
- **Screenshot Capture:** Optionally takes screenshots of live hosts with EyeWitness.
- **Customizable:** Supports options for threading, timeouts, output directories, logging, and more.
- **User-Friendly Output:** Merges, deduplicates, and organizes results for easy analysis.
- **Verbose Logging:** Optional debug output for troubleshooting.

## Requirements

- **Bash** (Linux/macOS/WSL recommended)
- **Tools:**
  - [Subfinder](https://github.com/projectdiscovery/subfinder)
  - [Amass](https://github.com/owasp-amass/amass)
  - [Assetfinder](https://github.com/tomnomnom/assetfinder)
  - [Sublist3r](https://github.com/aboul3la/Sublist3r)
  - [Httprobe](https://github.com/tomnomnom/httprobe)
  - [EyeWitness](https://github.com/FortyNorthSecurity/EyeWitness) (optional, for screenshots)
- **Python** (for Sublist3r)
- **Go** (for some tools)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Wise02/enum5.git
   cd enum5.sh
   ```

2. **Install dependencies:**
   - Follow the install commands in the script output if a tool is missing.
   - Example for Go-based tools:
     ```bash
     go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
     go install github.com/owasp-amass/amass/v4/...@latest
     go install github.com/tomnomnom/assetfinder@latest
     go install github.com/tomnomnom/httprobe@latest
     ```
   - For Sublist3r:
     ```bash
     pip install sublist3r
     ```
   - For EyeWitness (screenshots, optional):
     ```bash
     sudo apt install eyewitness
     ```

## Usage

```bash
./enum5.sh --verbose [options] <domain-or-URL>
```

### Options

- `--help`                Show help message and exit
- `--version`             Show script version and exit
- `--no-screenshots`      Skip screenshotting step
- `--threads N`           Set concurrency for tools (default: 10)
- `--timeout N`           Set per-tool timeout in seconds (default: 120)
- `--logfile FILE`        Set log file (default: enum5.log)
- `--output-dir DIR`      Set base output directory (default: current dir)
- `--verbose`             Enable verbose/debug output
- `--keep-old`            Keep old output files (do not overwrite)

### Examples

```bash
./enum5.sh --verbose example.com
./enum5.sh --verbose --no-screenshots --threads 20 --timeout 60 example.com
```

## Output

- **Raw outputs:** Individual tool results in the `recon` directory
- **Merged list:** All found subdomains combined
- **Deduped list:** Unique subdomains
- **Live hosts:** Subdomains responding to HTTP(S)
- **Screenshots:** (Optional) Captured screenshots of live hosts

## Next Steps

- Review the log file for errors or details.
- Check the screenshots directory for captured images.
- Use the merged and deduped lists for further reconnaissance.

## License

MIT License

---

**Happy hacking!**
