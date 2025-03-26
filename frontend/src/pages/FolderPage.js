import React from 'react';
import { Table, TableBody, TableCell, TableContainer, TableHead, TableRow, IconButton, Paper } from '@mui/material';
import { Delete, Archive, Restore } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import axios from 'axios';

const FolderTable = () => {
  const navigate = useNavigate();
  const [folders, setFolders] = useState([]);
  const [folderName, setFolderName] = useState('');
  const [message, setMessage] = useState('');

  const fetchFolders = async () => {
    try {
      const response = await axios.get('http://localhost:5000/api/v1/data/folders', {
        headers: {
          Authorization: `Bearer ${localStorage.getItem('access_token')}`,
        },
        withCredentials: true,
      });
      console.log(response.data);
      setFolders(response.data);
    } catch (error) {
      console.error('Error fetching folders:', error);
    }
  };
  useEffect(() => {
    fetchFolders();
  }, []);

  const handleFolderNameChange = (e) => {
    setFolderName(e.target.value);
  };

  const handleCreateFolder = async (e) => {
    if (!folderName) {
      setMessage('Folder name is required');
      return;
    }
    try {
      const response = await axios.post('http://localhost:5000/api/v1/data/cfolder', {
          name: folderName,
        }, 
        {
          withCredentials: true
      });
      if (response.status === 201) {
        setMessage('Folder created successfully!');
        setFolderName('');
      }
    } catch (error) {
      console.error('Error creating folder:', error);
      setMessage('Error creating folder. Please try again.');
    }
  };

  const handleDelete = async (folderId) => {
    try {
      const response = await axios.put(`http://localhost:5000/api/v1/folders/${folderId}/delete`);
      setFolders(folders.map(folder => 
        folder.id === folderId ? { ...folder, is_deleted: true } : folder
      ));
      console.log(response.data.msg);
    } catch (error) {
      console.error('Error deleting folder:', error);
    }
  };

  const handleArchive = async (folder) => {
    try {
      const folderName = folder.name
      const folderId = folder.id      
      const response = await axios.post(`http://localhost:5000/api/v1/data/archive`, {
        name: folderName,
      }, 
      {
        withCredentials: true
    });
      setFolders(folders.map(folder => 
        folder.id === folderId ? { ...folder, is_archived: true } : folder
      ));
      console.log(response.data.msg);
    } catch (error) {
      console.error('Error archiving folder:', error);
    }
  };

  const handleRestore = async (folder) => {
    try {
      const folderName = folder.name
      const folderId = folder.id      
      const response = await axios.post(`http://localhost:5000/api/v1/data/restore`, {
        name: folderName,
      }, 
      {
        withCredentials: true
      });
      
      // setFolders(folders.map(folder => 
      //   folder.id === folderId ? { ...folder, is_archived: true } : folder
      // ));
      console.log(response.data.msg);
    } catch (error) {
      console.error('Error archiving folder:', error);
    }
  };

  // Function to navigate to the UploadPage and pass folder data
  const handleFolderClick = (folder) => {
    console.log('folder ->', folder)
    navigate('/upload', { state: { folder } }); // Pass the folder data
  };
  const handleArchiveClick = (folder) => {
    console.log('folder ->', folder)
    handleArchive(folder)
  };
  const handleRestoreClick = (folder) => {
    console.log('folder ->', folder)
    handleRestore(folder)
  };

  return (
    <div>
      <div>
          <label>Folder Name:</label>
          <input 
            type="text" 
            value={folderName} 
            onChange={handleFolderNameChange} 
            required
            placeholder="Enter folder name"
          />
      </div>
      <button onClick={(e)=>{handleCreateFolder(e)}} handleCreateFolder>Create Folder</button>
      {message && <p>{message}</p>}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Folder</TableCell>
              <TableCell>Delete</TableCell>
              <TableCell>Archive</TableCell>
              <TableCell>Restore</TableCell>
              <TableCell>Asset Count</TableCell>
              <TableCell>Size</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {folders.map((row) => (
              <TableRow key={row.id}>
                <TableCell>
                  <span
                    style={{ color: 'blue', cursor: 'pointer' }}
                    onClick={() => handleFolderClick(row)}
                  >
                    {row.name}
                  </span>
                </TableCell>
                <TableCell>
                  <IconButton color="error">
                    <Delete />
                  </IconButton>
                </TableCell>
                <TableCell>
                  {
                    row.is_archived?
                    <span
                      style={{ color: 'blue', cursor: 'pointer' }}
                      onClick={() => handleArchiveClick(row)}
                    >
                      <IconButton color="primary">
                        <Archive />
                      </IconButton>
                      {}
                    </span>:
                    null
                  }
                </TableCell>
                <TableCell>
                {
                    row.is_archived?
                    <span
                      style={{ color: 'blue', cursor: 'pointer' }}
                      onClick={() => handleRestoreClick(row)}
                    >
                      <IconButton color="primary">
                        <Restore />
                      </IconButton>
                    </span>
                    :
                    null
                  }
                </TableCell>
                <TableCell>{row.asset_count}</TableCell>
                <TableCell>{row.size}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </div>
  );
};

export default FolderTable;
