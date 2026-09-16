import re

file_path = r'e:\development\SikkaPlay\backend\src\routes\user.routes.ts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import { claimSocialTaskUser } from '../controllers/socialTask.controller';\nimport { incrementGullak, claimGullakReward } from '../controllers/gullak.controller';"
content = content.replace("import { claimSocialTaskUser } from '../controllers/socialTask.controller';", import_stmt)

routes_code = """
// Gullak
router.post('/gullak/increment', incrementGullak);
router.post('/gullak/claim', claimGullakReward);

module.exports = router;
"""

content = content.replace("export default router;", routes_code) # just in case it exports default
if "export default router;" not in content:
    # let's just append if it ends with export default router
    content = re.sub(r'export default router;?', routes_code, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
