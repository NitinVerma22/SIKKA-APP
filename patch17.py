import re
file_path = 'lib/features/playground/screens/playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: _buildTabItem Text overflow
old_tab_text = """              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),"""

new_tab_text = """              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),"""

if old_tab_text in content:
    content = content.replace(old_tab_text, new_tab_text)
else:
    print("Warning: Could not find old_tab_text in file")

# Fix 2: _buildLoadMoreButton width overflow
old_btn_width = """        child: Center(
          child: SizedBox(
            width: 140,
            height: 40,"""

new_btn_width = """        child: Center(
          child: SizedBox(
            width: 160,
            height: 40,"""

if old_btn_width in content:
    content = content.replace(old_btn_width, new_btn_width)
else:
    print("Warning: Could not find old_btn_width in file")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
