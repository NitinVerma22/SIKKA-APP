import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\screens\win_600_coins_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_image = '''                            child: Image.asset(
                                isLast ? 'assets/images/games_hub/banner_gift.png' : 'assets/images/claim_gullak.webp',
                                width: 45,
                                height: 45,
                                fit: BoxFit.contain,
                                color: (!isLast && !isUnlocked) ? Colors.grey : null,
                                colorBlendMode: (!isLast && !isUnlocked) ? BlendMode.saturation : null,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  isLast ? Icons.card_giftcard : Icons.savings_rounded,
                                  color: isLast ? const Color(0xFFB45309) : const Color(0xFFF472B6),
                                  size: 30,
                                ),
                              ),'''

new_icon = '''                            child: Icon(
                                isLast ? Icons.card_giftcard : Icons.savings_rounded,
                                color: (!isLast && !isUnlocked) ? Colors.grey : (isLast ? const Color(0xFFB45309) : const Color(0xFFF472B6)),
                                size: 30,
                              ),'''

content = content.replace(old_image, new_icon)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Restored icon in win_600_coins_screen.dart")
