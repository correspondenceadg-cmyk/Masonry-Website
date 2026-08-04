#!/usr/bin/env python3
import sys
import requests
import json
from concurrent.futures import ThreadPoolExecutor

def check_s3(domain):
    variants = [
        f"https://{domain}.s3.amazonaws.com",
        f"https://{domain}.s3.us-east-1.amazonaws.com",
        f"https://s3.amazonaws.com/{domain}",
        f"https://{domain}.s3-website-us-east-1.amazonaws.com"
    ]
    for url in variants:
        try:
            r = requests.get(url, timeout=5)
            if r.status_code in [200, 403]:
                return {"url": url, "status": r.status_code, "type": "S3"}
        except: pass
    return None

def check_azure(domain):
    variants = [
        f"https://{domain}.blob.core.windows.net",
        f"https://{domain}.azurewebsites.net"
    ]
    for url in variants:
        try:
            r = requests.get(url, timeout=5)
            if r.status_code in [200, 403]:
                return {"url": url, "status": r.status_code, "type": "Azure"}
        except: pass
    return None

def main(domain):
    print(f"[*] Scanning cloud storage for: {domain}")
    results = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        future_s3 = executor.submit(check_s3, domain)
        future_azure = executor.submit(check_azure, domain)
        res_s3 = future_s3.result()
        res_azure = future_azure.result()
        if res_s3: results.append(res_s3)
        if res_azure: results.append(res_azure)
    print(f"[*] Found {len(results)} exposed cloud resources.")
    print(json.dumps(results, indent=2))
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 cloud_enum.py <domain>")
        sys.exit(1)
    main(sys.argv[1])