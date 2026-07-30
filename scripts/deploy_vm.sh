#!/bin/bash
set -e
apt update && apt install -y python3 python3-pip wget unzip osmium-tool zstd par2 curl
pip3 install -r requirements.txt
curl -fsSL https://ollama.com/install.sh | sh
ollama pull mistral
echo "VM ready. Run 'source .env' then start lenin.py"