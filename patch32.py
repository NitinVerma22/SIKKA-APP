import re

file_path = r'e:\development\SikkaPlay\lib\shared\layouts\main_layout.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add notificationProvider import
import_str = "import 'package:sikkaplay/core/navigation/app_navigator.dart';"
new_import = "import 'package:sikkaplay/core/navigation/app_navigator.dart';\nimport 'package:sikkaplay/features/notifications/providers/notification_provider.dart';"
content = content.replace(import_str, new_import)

# 2. Add badge count parameters to _buildNavItem
build_nav_item_old = r"""  Widget _buildNavItem\(
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
    bool isReels,
  \) \{"""

build_nav_item_new = """  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
    bool isReels,
    {int badgeCount = 0}
  ) {"""
content = re.sub(build_nav_item_old, build_nav_item_new, content)

# 3. Modify Row in build to pass badge counts
row_old = r"""                        _buildNavItem\(context, ref, 0, Icons\.home_rounded, context\.tr\('home', selectedLanguage\), selectedIndex, false\),
                        _buildNavItem\(context, ref, 1, Icons\.people_alt_rounded, selectedLanguage == 'Hindi' \? 'à¤«à¥\sà¤°à¥‡à¤‚à¤¡à¥\sà¤¸' : 'Friends', selectedIndex, false\),
                        _buildNavItem\(context, ref, 2, Icons\.monetization_on_rounded, selectedLanguage == 'Hindi' \? 'à¤…à¤°à¥\sà¤¨' : 'Earn', selectedIndex, false\),
                        _buildNavItem\(context, ref, 3, Icons\.chat_bubble_rounded, selectedLanguage == 'Hindi' \? 'à¤šà¥ˆà¤Ÿà¥\sà¤¸' : 'Chats', selectedIndex, false\),
                        _buildNavItem\(context, ref, 4, Icons\.person_rounded, context\.tr\('profile', selectedLanguage\), selectedIndex, false\),"""

row_new = """                        _buildNavItem(context, ref, 0, Icons.home_rounded, context.tr('home', selectedLanguage), selectedIndex, false),
                        _buildNavItem(context, ref, 1, Icons.people_alt_rounded, selectedLanguage == 'Hindi' ? 'फ़्रेंड्स' : 'Friends', selectedIndex, false),
                        _buildNavItem(context, ref, 2, Icons.monetization_on_rounded, selectedLanguage == 'Hindi' ? 'अर्न' : 'Earn', selectedIndex, false),
                        _buildNavItem(context, ref, 3, Icons.chat_bubble_rounded, selectedLanguage == 'Hindi' ? 'चैट्स' : 'Chats', selectedIndex, false, badgeCount: chatBadgeCount),
                        _buildNavItem(context, ref, 4, Icons.person_rounded, context.tr('profile', selectedLanguage), selectedIndex, false, badgeCount: profileBadgeCount),"""
# Wait, replacing literal hindi strings with regex is tricky. Let's just find the `mainAxisAlignment: MainAxisAlignment.spaceAround,` and replace the whole block up to `],`

row_block_old = r"mainAxisAlignment: MainAxisAlignment\.spaceAround,[\s\S]*?_buildNavItem\(context, ref, 4.*?false\),[\s\S]*?\],"
row_block_new = """mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, ref, 0, Icons.home_rounded, context.tr('home', selectedLanguage), selectedIndex, false),
                        _buildNavItem(context, ref, 1, Icons.people_alt_rounded, selectedLanguage == 'Hindi' ? 'फ़्रेंड्स' : 'Friends', selectedIndex, false),
                        _buildNavItem(context, ref, 2, Icons.monetization_on_rounded, selectedLanguage == 'Hindi' ? 'अर्न' : 'Earn', selectedIndex, false),
                        _buildNavItem(context, ref, 3, Icons.chat_bubble_rounded, selectedLanguage == 'Hindi' ? 'चैट्स' : 'Chats', selectedIndex, false, badgeCount: chatBadgeCount),
                        _buildNavItem(context, ref, 4, Icons.person_rounded, context.tr('profile', selectedLanguage), selectedIndex, false, badgeCount: profileBadgeCount),
                      ],"""

content = re.sub(row_block_old, row_block_new, content)

# 4. Add the calculations to build()
build_method_str = r"final selectedLanguage = ref\.watch\(languageProvider\);"
calc_str = """final selectedLanguage = ref.watch(languageProvider);
    
    // Badges calculation
    int profileBadgeCount = ref.watch(notificationProvider).unreadCount;
    int chatBadgeCount = ref.watch(globalPendingRequestsProvider).length;
    for (final friend in ref.watch(globalFriendsListProvider)) {
      chatBadgeCount += (friend['unreadCount'] as int? ?? 0);
    }"""
content = content.replace(build_method_str, calc_str)

# 5. Render the badge inside _buildNavItem
# It's an AnimatedContainer with Icon inside. We need to wrap the Icon with a Stack or Badge
icon_block_old = r"""Icon\(
                icon,
                color: color,
                size: 24,
              \),"""

icon_block_new = """Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63), // Pink badge color
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),"""
content = re.sub(icon_block_old, icon_block_new, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("main_layout.dart patched successfully")
