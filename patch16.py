import re
file_path = 'lib/features/playground/screens/playground_friends_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = """                      Row(
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),"""

new_str = """                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),"""

if old_str in content:
    content = content.replace(old_str, new_str)
else:
    print("Not found! trying regex")
    content = re.sub(
        r"Text\(\s*displayName,\s*style: GoogleFonts\.outfit\(color: const Color\(0xFF1F2937\), fontWeight: FontWeight\.bold, fontSize: 15\),\s*maxLines: 1,\s*overflow: TextOverflow\.ellipsis,\s*\),",
        r"Flexible(\n                            child: Text(\n                              displayName,\n                              style: GoogleFonts.outfit(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                            ),\n                          ),",
        content
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
