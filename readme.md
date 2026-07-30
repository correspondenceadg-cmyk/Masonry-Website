# Keystone Masonry – OSINT Ad Intelligence Module

Decoy masonry site + hidden dashboard with tracking scraper and Ollama LLM compilation.

## Features
- Public brick masonry decoy site
- Hidden access via `Ctrl+Shift+A` – requires username, PGP key (cached), and 4‑6 digit PIN
- Dashboard with two functions:
  1. **Track Scraper** – fetches live tracking timeline from parcelsapp.com
  2. **LLM Compilation** – uses local Ollama (mistral) to predict recipient name/address from tracking number

## Deployment

1. Clone repo
2. Install dependencies: `pip install -r requirements.txt`
3. Set API keys in `.env` (see `API_KEYS.md`)
4. Run data collection and compression:
   ```bash
   bash scripts/build_cache.sh   # downloads all data for Houston/LA
   bash scripts/compress_archive.sh  # compresses to data_cache.tar.zst