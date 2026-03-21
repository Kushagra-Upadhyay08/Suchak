const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

async function fixUser() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    console.log('Connected to MongoDB');
    
    // Fix "Motabhai" engineer
    const res = await User.updateOne(
      { name: 'Motabhai', role: 'engineer' },
      { $set: { employeeId: '007' } } // Giving a demo ID
    );
    console.log('Update result:', res);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fixUser();
