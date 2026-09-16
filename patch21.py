import re
file_path = 'lib/features/games/shared/utils/game_claim_dialog.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';\n"
if "win_600_provider.dart" not in content:
    content = content.replace("import 'package:sikkaplay/core/sync/sync_coordinator.dart';", "import 'package:sikkaplay/core/sync/sync_coordinator.dart';\n" + import_stmt)

# Add incrementGullak call
old_code = """        if (result != null && result['success'] == true) {
          final int coinsWon = result['coinsEarned'] ?? 0;
          ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
          onClaimCompleted();"""

new_code = """        if (result != null && result['success'] == true) {
          final int coinsWon = result['coinsEarned'] ?? 0;
          ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
          ref.read(win600Provider.notifier).incrementGullak();
          onClaimCompleted();"""

if "incrementGullak();" not in content:
    content = content.replace(old_code, new_code)
else:
    print("incrementGullak(); is already there!")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
