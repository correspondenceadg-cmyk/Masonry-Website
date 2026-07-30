#(at end, add chmod + x collect all.sh)


#!/bin/bash
set -e

# --- Config ---
COUNTIES=(
    "state:48 county:201"   # Harris, TX
    "state:06 county:037"   # Los Angeles, CA
)
DATA_DIR="./data_collection"
mkdir -p "$DATA_DIR"/{census,kaggle,osm,geonames,trends,dataworld}

# --- Load API keys ---
source ~/.keys.env || { echo "Missing ~/.keys.env"; exit 1; }

# --- Install dependencies ---
apt update && apt install -y python3 python3-pip wget unzip osmium-tool rclone
pip3 install census pandas kagglehub datadotworld pytrends requests beautifulsoup4

# --- 1. Census / Data.gov ---
python3 <<EOF
import pandas as pd
import requests
from census import Census

c = Census("$CENSUS_KEY")
tables = ["B01003","B23025","B25003","B28001","C24010","B19013","B08012"]
counties = [{"state":"06","county":"037"}, {"state":"48","county":"201"}]

for cnt in counties:
    for tbl in tables:
        try:
            data = c.acs5.get((tbl,), geo={"for": f"county:{cnt['county']}", "in": f"state:{cnt['state']}"})
            df = pd.DataFrame(data)
            df.to_csv(f"$DATA_DIR/census/{cnt['state']}_{cnt['county']}_{tbl}.csv", index=False)
        except:
            pass

# Retail trade (Economic Census)
retail_urls = [
    "https://api.census.gov/data/2023/ecn/retail?get=NAICS_TTL,SALES,SALES_EMP&for=county:037&in=state:06",
    "https://api.census.gov/data/2023/ecn/retail?get=NAICS_TTL,SALES,SALES_EMP&for=county:201&in=state:48"
]
for url in retail_urls:
    r = requests.get(url).json()
    df = pd.DataFrame(r)
    df.to_csv("$DATA_DIR/census/retail_trade.csv", mode='a', header=False)
EOF

# --- 2. Kaggle (all datasets with keywords) ---
python3 <<EOF
import kagglehub
from kagglehub import KaggleDataset
import os

keywords = [
    "houston", "los angeles", "shipping", "logistics", "jewelry", "electronics",
    "antiques", "precious metals", "copper", "platinum", "gold", "silver",
    "tlaxco silver", "24k gold", "copper wiring", "catalytic converter",
    "UPS", "fedex", "DHL", "USPS", "scrap metal", "e-waste", "gold buyer",
    "jewelry store", "antique shop", "electronics recycling", "copper scrap",
    "platinum jewelry", "silver coins"
]
for kw in keywords:
    results = KaggleDataset.search(kw, page_size=50)
    for r in results:
        try:
            path = kagglehub.dataset_download(r.handle)
            os.system(f"mv {path} $DATA_DIR/kaggle/{kw}_{r.handle.replace('/', '_')}")
        except:
            continue
EOF

# --- 3. OpenStreetMap (county extracts) ---
wget -q https://download.geofabrik.de/north-america/us/texas-latest.osm.pbf -O /tmp/texas.osm.pbf
wget -q https://download.geofabrik.de/north-america/us/california-latest.osm.pbf -O /tmp/california.osm.pbf
# Harris County, TX (approx bounding box)
osmium extract -b -95.4,29.5,-95.0,30.1 /tmp/texas.osm.pbf -o "$DATA_DIR/osm/houston.osm.pbf"
# Los Angeles County, CA (approx bounding box)
osmium extract -b -118.4,33.5,-117.8,34.5 /tmp/california.osm.pbf -o "$DATA_DIR/osm/la.osm.pbf"
rm /tmp/texas.osm.pbf /tmp/california.osm.pbf

# --- 4. GeoNames (filter TX/CA + city names) ---
wget -q http://download.geonames.org/export/dump/US.zip -O /tmp/US.zip
unzip -q /tmp/US.zip -d /tmp/geonames
grep -E "\t(TX|CA)\t" /tmp/geonames/US.txt > /tmp/geonames_tx_ca.txt
grep -E "(Houston|Los Angeles)" /tmp/geonames_tx_ca.txt > "$DATA_DIR/geonames/houston_la.txt"
rm -rf /tmp/geonames /tmp/US.zip

# --- 5. Google Trends (dynamic keywords) ---
python3 <<EOF
from pytrends.request import TrendReq
import pandas as pd

keywords = [
    "shipping", "delivery", "courier", "parcel", "jewelry", "electronics",
    "antiques", "precious metals", "copper", "platinum", "gold", "silver",
    "catalytic converter", "copper wiring", "UPS", "fedex", "DHL", "USPS",
    "scrap metal", "gold buyer", "antique shop", "electronics recycling"
]
geocodes = ["US-TX-618", "US-CA-803"]  # Houston and LA DMAs
pytrends = TrendReq(hl='en-US', tz=360)
for geo in geocodes:
    for i in range(0, len(keywords), 5):
        kw_chunk = keywords[i:i+5]
        pytrends.build_payload(kw_chunk, timeframe='2023-01-01 2026-07-30', geo=geo)
        df = pytrends.interest_over_time()
        df.to_csv(f"$DATA_DIR/trends/{geo}_{'_'.join(kw_chunk)}.csv")
EOF

# --- 6. Data.world (with keywords) ---
python3 <<EOF
import datadotworld as dw
import os
dw.api_key = "$DATAWORLD_KEY"
keywords = ["houston", "los angeles", "shipping", "retail", "jewelry", "electronics"]
for kw in keywords:
    results = dw.search_datasets(query=kw, limit=50)
    for res in results:
        try:
            ds = dw.load_dataset(res['id'])
            ds.dataframes.to_csv(f"$DATA_DIR/dataworld/{kw}_{res['id']}.csv", index=False)
        except:
            continue
EOF

# --- 7. (Optional) Upload to Backblaze B2 ---
# Uncomment and configure rclone remote named 'b2' first
# rclone copy "$DATA_DIR" b2:your-bucket-name/houston-la-data --progress

echo "Data collection complete. Check $DATA_DIR"