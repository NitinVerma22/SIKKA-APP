import re
file_path = 'lib/features/playground/screens/playground_lobby_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Change button gradient
content = content.replace("colors: [Color(0xFF8A2BE2), Color(0xFF6F5EFA)],", "colors: [Color(0xFFF2338A), Color(0xFF7948F8)],")
content = content.replace("color: const Color(0xFF6F5EFA).withValues(alpha: 0.4),", "color: const Color(0xFF7948F8).withValues(alpha: 0.4),")

# Replace call in build
content = content.replace("_buildPlaytimeCrates(),", "_buildMeetNewPeopleBanner(),")

# Add _buildMeetNewPeopleBanner function before _buildConnectButton
banner_func = """  Widget _buildMeetNewPeopleBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/meet_new.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildConnectButton"""

content = content.replace("  Widget _buildConnectButton", banner_func)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
