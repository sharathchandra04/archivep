import React from 'react';
import { Navigate } from 'react-router-dom';

// Protected route component that checks if the user is authenticated
const PrivateRoute = ({ element }) => {
  const isAuthenticated = localStorage.getItem('auth') !== null;

  return isAuthenticated ? element : <Navigate to="/login" replace />;
};

export default PrivateRoute;