const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

async function fixUser() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    console.log('Connected to MongoDB');
    
    // Fix "Hello" engineer
    const res = await User.updateOne(
      { name: 'Hello', role: 'engineer' },
      { $set: { employeeId: '1503' } }
    );
    console.log('Update result:', res);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fixUser();
