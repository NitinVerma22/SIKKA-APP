import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the subtitle widget of Make Friends
content = re.sub(
    r"subtitleWidget: const Text\(\s*'Connect, chat and get exciting gifts!',\s*maxLines: 2,\s*style: TextStyle\(fontSize: 12, color: Colors\.black54, fontWeight: FontWeight\.w500, height: 1\.1\),\s*\),",
    r"subtitleWidget: const Text(\n                            'Connect,\\nchat and get\\nexciting gifts!',\n                            maxLines: 3,\n                            style: TextStyle(fontSize: 14, color: Color(0xFFC2185B), fontWeight: FontWeight.w800, height: 1.1),\n                          ),",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
