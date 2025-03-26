import React, { useState, useEffect } from 'react';
import { Button, IconButton, LinearProgress, Box, Typography } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import axios from 'axios';
import { useLocation } from 'react-router-dom';

  
const FileUploadComponent = (a) => {
  const location = useLocation();
  const state = location.state;
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [successCount, setSuccessCount] = useState(0);
  const [failureCount, setFailureCount] = useState(0);
  const [uploadProgress, setUploadProgress] = useState(0); // Progress for each file upload

  useEffect(() => {
    console.log('a ----> ', a, state)
  }, [])
  const handleFileSelect = (event) => {
    setSelectedFiles(event.target.files);
  };

  const handleUpload = async () => {
    if (selectedFiles.length === 0) return;

    setUploading(true);
    setSuccessCount(0);
    setFailureCount(0);
    setUploadProgress(0);
    const totalFiles = selectedFiles.length;
    let success = 0;
    let failure = 0;
    console.log(document.cookie);
    for (let i = 0; i < totalFiles; i++) {
      try {
        const file = selectedFiles[i];

        // Create FormData to send files
        const formData = new FormData();
        formData.append('file', file);
        formData.append('folder', state.folder.name);

        // Replace this URL with your backend upload endpoint
        const response = await axios.post('http://localhost:5000/api/v1/data/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          withCredentials: true,
          onUploadProgress: (progressEvent) => {
            const progress = Math.round((progressEvent.loaded / progressEvent.total) * 100);
            setUploadProgress(progress);
          },
        });

        if (response.status === 200) {
          success++;
        } else {
          failure++;
        }
      } catch (error) {
        console.error('Error uploading file', error);
        failure++;
      }

      // Update success/failure count
      setSuccessCount(success);
      setFailureCount(failure);

      // Update progress
      setUploadProgress(((i + 1) / totalFiles) * 100);
    }

    setUploading(false); // Set uploading to false after all files are processed
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', height: '100%' }}>
      {/* Left side part (25%) */}
      <Box sx={{ width: '25%', padding: '20px', borderRight: '1px solid #ddd' }}>
        <Typography variant="h6" sx={{ marginBottom: '10px' }}>
          Upload Files
        </Typography>

        <IconButton
          color="primary"
          component="label"
          sx={{ marginBottom: '10px' }}
        >
          <AddIcon />
          <input
            type="file"
            multiple
            hidden
            onChange={handleFileSelect}
            accept="image/*"
          />
        </IconButton>

        <Button
          variant="contained"
          color="primary"
          onClick={handleUpload}
          disabled={uploading || selectedFiles.length === 0}
          sx={{ marginBottom: '10px' }}
        >
          {uploading ? 'Uploading...' : 'Upload'}
        </Button>

        <Typography variant="body2" color="textSecondary">
          Success: {successCount}
        </Typography>
        <Typography variant="body2" color="textSecondary">
          Failure: {failureCount}
        </Typography>

        <LinearProgress
          variant="determinate"
          value={uploadProgress}
          sx={{ marginTop: '20px' }}
        />
      </Box>

      {/* Right side part (75%) - Empty for now */}
      <Box sx={{ width: '75%', padding: '20px' }}>
        {/* You can add additional content here */}
        <Typography variant="h6">File Upload Progress</Typography>
      </Box>
    </Box>
  );
};

export default FileUploadComponent;
