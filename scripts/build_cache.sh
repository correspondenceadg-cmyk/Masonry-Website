#!/bin/bash
set -e
DATA_DIR="./data_collection"
mkdir -p "$DATA_DIR"/{census,kaggle,osm,geonames,trends,dataworld}
source ~/.keys.env || { echo "Missing ~/.keys.env"; exit 1; }
apt update && apt install -y python3 python3-pip wget unzip osmium-tool zstd par2
pip3 install census pandas kagglehub datadotworld pytrends requests beautifulsoup4

python3 <<EOF
import pandas as pd, requests
from census import Census
c = Census("$CENSUS_KEY")
tables = ["B01003","B23025","B25003","B28001","C24010","B19013","B08012"]
counties = [{"state":"06","county":"037"}, {"state":"48","county":"201"}]
for cnt in counties:
    for tbl in tables:
        try:
            data = c.acs5.get((tbl,), geo={"for": f"county:{cnt['county']}", "in": f"state:{cnt['state']}"})
            pd.DataFrame(data).to_csv(f"$DATA_DIR/census/{cnt['state']}_{cnt['county']}_{tbl}.csv", index=False)
        except: pass
for url in ["https://api.census.gov/data/2023/ecn/retail?get=NAICS_TTL,SALES,SALES_EMP&for=county:037&in=state:06",
            "https://api.census.gov/data/2023/ecn/retail?get=NAICS_TTL,SALES,SALES_EMP&for=county:201&in=state:48"]:
    pd.DataFrame(requests.get(url).json()).to_csv("$DATA_DIR/census/retail_trade.csv", mode='a', header=False)
EOF

python3 <<EOF
import kagglehub, os
keywords = ["houston","los angeles","shipping","logistics","jewelry","electronics","antiques","precious metals","copper","platinum","gold","silver","tlaxco silver","24k gold","copper wiring","catalytic converter","UPS","fedex","DHL","USPS","scrap metal","e-waste","gold buyer","jewelry store","antique shop","electronics recycling","copper scrap","platinum jewelry","silver coins"]
for kw in keywords:
    for r in kagglehub.KaggleDataset.search(kw, page_size=50):
        try:
            path = kagglehub.dataset_download(r.handle)
            os.system(f"mv {path} $DATA_DIR/kaggle/{kw}_{r.handle.replace('/', '_')}")
        except: continue
EOF

wget -q https://download.geofabrik.de/north-america/us/texas-latest.osm.pbf -O /tmp/tx.osm.pbf
wget -q https://download.geofabrik.de/north-america/us/california-latest.osm.pbf -O /tmp/ca.osm.pbf
osmium extract -b -95.4,29.5,-95.0,30.1 /tmp/tx.osm.pbf -o "$DATA_DIR/osm/houston.osm.pbf"
osmium extract -b -118.4,33.5,-117.8,34.5 /tmp/ca.osm.pbf -o "$DATA_DIR/osm/la.osm.pbf"
rm /tmp/tx.osm.pbf /tmp/ca.osm.pbf

wget -q http://download.geonames.org/export/dump/US.zip -O /tmp/US.zip
unzip -q /tmp/US.zip -d /tmp/geonames
grep -E "\t(TX|CA)\t" /tmp/geonames/US.txt > /tmp/tx_ca.txt
grep -E "(Houston|Los Angeles)" /tmp/tx_ca.txt > "$DATA_DIR/geonames/houston_la.txt"
rm -rf /tmp/geonames /tmp/US.zip

python3 <<EOF
from pytrends.request import TrendReq
import pandas as pd
keywords = ["shipping","delivery","courier","parcel","jewelry","electronics","antiques","precious metals","copper","platinum","gold","silver","catalytic converter","copper wiring","UPS","fedex","DHL","USPS","scrap metal","gold buyer","antique shop","electronics recycling"]
geocodes = ["US-TX-618","US-CA-803"]
pytrends = TrendReq(hl='en-US', tz=360)
for geo in geocodes:
    for i in range(0, len(keywords), 5):
        chunk = keywords[i:i+5]
        pytrends.build_payload(chunk, timeframe='2023-01-01 2026-07-30', geo=geo)
        pytrends.interest_over_time().to_csv(f"$DATA_DIR/trends/{geo}_{'_'.join(chunk)}.csv")
EOF

python3 <<EOF
import datadotworld as dw
dw.api_key = "$DATAWORLD_KEY"
for kw in ["houston","los angeles","shipping","retail","jewelry","electronics"]:
    for res in dw.search_datasets(query=kw, limit=50):
        try:
            ds = dw.load_dataset(res['id'])
            ds.dataframes.to_csv(f"$DATA_DIR/dataworld/{kw}_{res['id']}.csv", index=False)
        except: continue
EOF

echo "Data collection complete. Check $DATA_DIR"