# smart-archive-extractor
Smart Archive Extractor is a lightweight Windows (PowerShell 5.1+/Win11) utility that recursively scans a folder, extracts supported archives (.zip, .7z, .gz, .tgz) into their parent dirs, and moves originals to a root safekeeping folder. Its Multi‑Pass engine handles nested archives and isolates its safekeep to avoid loops.
