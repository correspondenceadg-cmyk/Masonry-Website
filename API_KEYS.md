# API Key Acquisition

## 1. Census API
- Go to https://api.census.gov/data/key_signup.html
- Enter email → key sent instantly.
- Store as `CENSUS_KEY`.

## 2. Kaggle API
- Log in to https://www.kaggle.com
- Settings → API → Create New Token → downloads `kaggle.json`
- Extract `username` and `key`.
- Store as `KAGGLE_USERNAME` and `KAGGLE_KEY`.

## 3. Data.world API
- Sign up at https://data.world
- Settings → API → Generate API Key.
- Store as `DATAWORLD_KEY`.

## 4. Google Trends
- No API key needed.

## 5. Ollama
- No API key – install locally.
- Pull model: `ollama pull mistral`.
- Set `OLLAMA_URL=http://localhost:11434/api/generate`.

All keys go into `.env` on the VM (not committed).