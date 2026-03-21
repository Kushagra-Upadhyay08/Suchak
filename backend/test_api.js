const axios = require('axios');

async function testApi() {
  try {
    const baseUrl = 'http://localhost:5000/api';
    
    // 1. Login as admin
    console.log('Logging in as admin...');
    const loginRes = await axios.post(`${baseUrl}/auth/login`, {
      name: 'Kushagra',
      password: 'no' // I'll assume the password is "no" or check it
    });
    
    const token = loginRes.data.token;
    console.log('Login successful. Token obtained.');
    
    // 2. Fetch engineers
    console.log('Fetching engineers...');
    const engRes = await axios.get(`${baseUrl}/auth/engineers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('Engineers received:', engRes.data);
    console.log('Count:', engRes.data.length);
    
  } catch (err) {
    console.error('API Test Failed:', err.response ? err.response.data : err.message);
  }
}

testApi();
