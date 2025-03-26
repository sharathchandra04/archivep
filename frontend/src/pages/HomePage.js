import React from 'react';
import { Link } from 'react-router-dom';

function HomePage() {
  return (
    <div>
      <h1>Welcome to the React App</h1>
      <nav>
        <ul>
          <li><Link to="/login">Login</Link></li>
          <li><Link to="/register">Register</Link></li>
          {/* <li><Link to="/upload">Upload Images</Link></li> */}
          <li><Link to="/home">Home</Link></li>
        </ul>
      </nav>
    </div>
  );
}

export default HomePage;
