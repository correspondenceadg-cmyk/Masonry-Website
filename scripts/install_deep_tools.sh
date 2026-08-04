#!/bin/bash
set -e
echo "[*] Installing deep audit tools..."
apt update
apt install -y nmap jq curl wget git python3 python3-pip wordlists

# Install Go tools
apt install -y golang-go
export PATH=$PATH:/root/go/bin
echo 'export PATH=$PATH:/root/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:/root/go/bin' >> ~/.profile
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/ffuf/ffuf@latest
go install github.com/OJ/gobuster/v3@latest

# Install Python OSINT tools (requests already covered in requirements.txt)
pip3 install theHarvester dnspython s3scanner awscli

# Install DNSRecon
apt install -y dnsrecon

# Install WhatWeb
git clone https://github.com/urbanadventurer/WhatWeb.git /opt/WhatWeb
cd /opt/WhatWeb && git checkout v0.5.5 && cd ~

# Install testssl.sh (git clone instead of pip)
git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl.sh
ln -s /opt/testssl.sh/testssl.sh /usr/local/bin/testssl.sh

echo "[!] Critical: Run 'source ~/.bashrc' or logout/login before starting lenin.py."
echo "[!] Go binaries (subfinder, httpx, nuclei) are now installed."