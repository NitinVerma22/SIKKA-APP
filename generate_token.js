const jwt = require('jsonwebtoken');
const token = jwt.sign({ userId: '65f6f890c5b44c688d22e037' }, 'super-secret-sikkaplay-key', { expiresIn: '1d' });
console.log(token);
