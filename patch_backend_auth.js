const fs = require('fs');
const path = 'backend/src/controllers/auth.controller.ts';
let content = fs.readFileSync(path, 'utf8');

content = content.replace(
    'const { firebaseUid, email, name, city, gender, referredBy, deviceId, username } = req.body;',
    'const { firebaseUid, email, name, city, gender, referredBy, deviceId, username, phoneNumber } = req.body;'
);

content = content.replace(
    \      // Auto-generate a dummy phone number for Google users\\n      const formattedPhone = \\\G-\\\\\\;\,
    \      // Use provided phone number or fallback to dummy phone number for Google users\\n      let formattedPhone = phoneNumber;\\n      if (formattedPhone) {\\n        if (!formattedPhone.startsWith('+')) {\\n          formattedPhone = '+91' + formattedPhone;\\n        }\\n      } else {\\n        formattedPhone = \\\G-\\\\\\;\\n      }\
);
content = content.replace(
    \      // Auto-generate a dummy phone number for Google users\\r\\n      const formattedPhone = \\\G-\\\\\\;\,
    \      // Use provided phone number or fallback to dummy phone number for Google users\\n      let formattedPhone = phoneNumber;\\n      if (formattedPhone) {\\n        if (!formattedPhone.startsWith('+')) {\\n          formattedPhone = '+91' + formattedPhone;\\n        }\\n      } else {\\n        formattedPhone = \\\G-\\\\\\;\\n      }\
);


fs.writeFileSync(path, content, 'utf8');
console.log('Backend patched!');
