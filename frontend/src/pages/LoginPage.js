import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
//   const history = useHistory();  // Hook to navigate after login
  const navigate = useNavigate();
  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Make a POST request to Flask login route
      const response = await axios.post('http://localhost:5000/api/v1/users/login', { email, password }, {
        withCredentials: true,
      });
      if (response.status === 200) {
        console.log('Login successful', response.data);
        localStorage.setItem('auth', 'True');
        navigate('/home');  // You can change '/home' to your target page
      }
    } catch (error) {
      console.error('Error logging in', error);
    }
  };

  return (
    <div>
      <h2>Login</h2>
      <form onSubmit={handleSubmit}>
        <div>
          <label>Email:</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </div>
        <div>
          <label>Password:</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </div>
        <button type="submit">Login</button>
      </form>
    </div>
  );
}

export default LoginPage;
