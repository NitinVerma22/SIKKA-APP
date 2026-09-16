import re
file_path = 'lib/features/playground/screens/playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: _buildTabItem Text overflow
content = re.sub(
    r"Text\(\s*title,\s*style: GoogleFonts\.outfit\(\s*color: isSelected \? Colors\.white : Colors\.black54,\s*fontWeight: FontWeight\.bold,\s*fontSize: 12,\s*\),\s*\),",
    r"Flexible(\n                child: Text(\n                  title,\n                  style: GoogleFonts.outfit(\n                    color: isSelected ? Colors.white : Colors.black54,\n                    fontWeight: FontWeight.bold,\n                    fontSize: 12,\n                  ),\n                  maxLines: 1,\n                  overflow: TextOverflow.ellipsis,\n                ),\n              ),",
    content
)

# Fix 2: _buildLoadMoreButton width overflow
content = re.sub(
    r"width: 140,\s*height: 40,\s*child: ElevatedButton\(",
    r"width: 160,\n            height: 40,\n            child: ElevatedButton(",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
