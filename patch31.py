import re

file_path = r'e:\development\SikkaPlay\lib\features\home\screens\home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the AdScaleX onTap implementation
old_onTap = r"onTap: \(\) { final userId = ref\.read\(userProvider\)\.userData\?\['id'\]\?\.toString\(\) \?\? ref\.read\(userProvider\)\.userData\?\['_id'\]\?\.toString\(\) \?\? ''; final appKey = '7531'; AdScaleXOfferwallService\.openOfferwall\(context, userId, appKey\); },"

new_onTap = """onTap: () {
                          if (_isAdScaleXOpening) return;
                          setState(() {
                            _isAdScaleXOpening = true;
                          });
                          final userState = ref.read(userProvider);
                          final configState = ref.read(configProvider);
                          final userId = userState.userData?['id']?.toString() ?? userState.userData?['_id']?.toString() ?? '';
                          final remoteAppKey = configState.config?['adScaleXAppKey'] ?? configState.config?['adscalexAppKey'];
                          final appKey = remoteAppKey?.toString() ?? 'psk_NfPTjRGS0a5f6vcljv0ScBZohLYIxOFsdfCRE9kfrtQ';
                          
                          AdScaleXOfferwallService.openOfferwall(context, userId, appKey)
                              .whenComplete(() {
                            if (mounted) {
                              setState(() {
                                _isAdScaleXOpening = false;
                              });
                            }
                          });
                        },"""

if re.search(old_onTap, content):
    content = re.sub(old_onTap, new_onTap, content)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched successfully")
else:
    print("Could not find the exact onTap string to replace")
