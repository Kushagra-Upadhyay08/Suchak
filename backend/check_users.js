const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');

async function checkUsers() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    console.log('Connected to MongoDB');
    
    const users = await User.find();
    console.log(`Found ${users.length} users:`);
    users.forEach((u, i) => {
      console.log(`${i+1}. Name: "${u.name}", Role: "${u.role}", EmpID: "${u.employeeId}"`);
    });
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkUsers();
