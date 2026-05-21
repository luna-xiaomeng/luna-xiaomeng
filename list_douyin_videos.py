"""List all videos from a Douyin user"""
import json, sys
data = json.load(sys.stdin)
entries = data.get("entries", [])
print(f"Total videos found: {len(entries)}")
for e in entries[:50]:
    title = e.get("title", "")[:80]
    vid = e.get("id", "")
    dur = e.get("duration", 0)
    print(f"  [{vid}] {dur}s - {title}")
# Output IDs for later download
print("\n---IDS---")
for e in entries:
    print(e.get("id", ""))
