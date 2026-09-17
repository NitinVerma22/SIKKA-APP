import re

file_path = r'e:\development\SikkaPlay\lib\features\games\shared\utils\game_claim_dialog.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = """    final configState = ref.read(appConfigProvider);
    final String sequenceStr = configState.config?['gullakAdSequence'] ??
        'rewarded_interstitial,rewarded,interstitial';
    final List<String> sequence =
        sequenceStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    if (sequence.isEmpty) sequence.add('rewarded');
    final int claimsToday =
        ref.read(userProvider).userData?['gullakClaimsToday'] ?? 0;
    final String adType = sequence[claimsToday % sequence.length];"""

new_logic = """    final configState = ref.read(appConfigProvider);
    // User requested to only show 'rewarded' ads for gullak claim
    final String adType = 'rewarded';"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated game_claim_dialog.dart")
else:
    print("Could not find the target string.")
