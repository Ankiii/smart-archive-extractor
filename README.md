# Smart Archive Extractor

A robust, interactive PowerShell automation utility designed to scan directories recursively, extract compressed files into their parent directories without creating redundant wrapper folders, and cleanly isolate original archives into a central vault. 

Built specifically for Windows environments running **PowerShell 5.1+** (validated on Windows 11).

---

## 🚀 Features

* **Multi-Format Support:** Handles `.zip`, `.7z`, `.gz`, and `.tgz` formats seamlessly via 7-Zip integration.
* **Smart Multi-Pass Extraction:** If an extracted archive contains *more* compressed files inside it, the tool runs consecutive extraction passes. 
* **Zero-Clutter Archive Isolation:** 
  * **Top-Level Archives** are extracted and moved to a dedicated safekeeping directory.
  * **Nested Archives** (found inside other archives) are extracted and automatically deleted to keep your safekeeping folder clean.
* **Overwrite Protection:** Utilizes 7-Zip's native auto-rename feature (`-aot`) to gracefully append increments (e.g., `file_1.txt`) if filename collisions occur during extraction.
* **Infinite Loop Prevention:** Actively ignores the safekeeping directory during recursive scans, even if it resides inside your target directory.
* **Live Auditing:** Generates a detailed timestamped execution log (`extraction_log.txt`) inside your target directory.

---

## 🛠️ Prerequisites

This script leverages the high-performance command-line interface of **7-Zip**. 

1. Ensure **7-Zip** is installed on your machine.
2. Note your `7z.exe` file location (Default fallback baked into the script is `E:\VIRTUALIZATION\TOOLS\7z\7-Zip\7z.exe`).

---

## 💻 How to Use

1. Download or clone `Extract-AndArchive.ps1` to your local machine.
2. Open PowerShell and navigate to the directory containing the script.
3. Launch the script:
   ```powershell
   .\Extract-AndArchive.ps1