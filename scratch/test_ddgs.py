from duckduckgo_search import DDGS
import json

try:
    ddgs = DDGS()
    # Try news instead of text
    results = ddgs.news("Global", max_results=5)
    print(json.dumps(list(results), indent=2))
except Exception as e:
    print(f"Error: {e}")
