import re

file_path = r'e:\development\SikkaPlay\backend\src\routes\admin.routes.ts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_pattern = re.compile(r'(deleteWithdrawalOptionAdmin\n} from \'../controllers/admin\.controller\';)')
content = import_pattern.sub(r'deleteWithdrawalOptionAdmin,\n  getCoinDistribution,\n  getUpcomingWithdrawals\n} from \'../controllers/admin.controller\';', content)

route_pattern = re.compile(r'(router\.get\(\'/stats\', getDashboardStats\);)')
content = route_pattern.sub(r'\1\nrouter.get(\'/coin-distribution\', getCoinDistribution);\nrouter.get(\'/upcoming-withdrawals\', getUpcomingWithdrawals);', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated admin.routes.ts")
