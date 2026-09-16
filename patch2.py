import re
file_path = 'lib/features/home/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("AdScaleXOfferwallService.instance.showOfferwall(context, ref)", "{ final userId = ref.read(userProvider).user?.uid ?? ''; final appKey = '7531'; AdScaleXOfferwallService.openOfferwall(context, userId, appKey); }")
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
