const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

async function testQuery() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    console.log('Connected to MongoDB');
    
    // Test the exact query used in the route
    const engineers = await User.find({ role: 'engineer' }).select('name employeeId _id');
    console.log('Query Result (select):');
    console.log(JSON.stringify(engineers, null, 2));
    console.log('Count:', engineers.length);
    
    // Test without select just in case
    const allEngineers = await User.find({ role: 'engineer' });
    console.log('All engineers count:', allEngineers.length);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

testQuery();
