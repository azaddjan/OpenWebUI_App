/**
 * Main Process for Open-WebUI Electron App
 * Author: Azad Djan
 * Website: https://azaddjan.com
 * Date: 2024-12-03
 * Description: Entry point for the Electron application.
 */


const { app, BrowserWindow } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const http = require('http');

let pythonProcess;
let mainWindow;

// Set environment variables
process.env.WEBUI_AUTH = process.env.WEBUI_AUTH || "False";
// process.env.ENABLE_LOGIN_FORM = process.env.ENABLE_LOGIN_FORM || "True";
process.env.WEBUI_NAME = process.env.WEBUI_NAME || "Open WebUI";

console.log("Environment variables loaded:");
console.log("WEBUI_AUTH:", process.env.WEBUI_AUTH);
// console.log("ENABLE_LOGIN_FORM:", process.env.ENABLE_LOGIN_FORM);
console.log("WEBUI_NAME:", process.env.WEBUI_NAME);

function startPythonServer() {
  // Use the correct path to the Python executable
  const isDev = process.env.NODE_ENV === 'development' || !app.isPackaged;
  const command = isDev
    ? path.join(__dirname, '.venv', 'bin', 'open-webui') // Development path
    : path.join(process.resourcesPath, '.venv', 'bin', 'open-webui'); // Packaged app path

  const args = ['serve', '--port', '8080'];

  console.log(`Starting Python server from: ${command}`);

  const pythonProcess = spawn(command, args, {
    env: {
      ...process.env,
      PATH: isDev
        ? `${path.join(__dirname, '.venv', 'bin')}:${process.env.PATH}`
        : `${path.join(process.resourcesPath, '.venv', 'bin')}:${process.env.PATH}`, // Ensure correct PATH
    },
  });

  pythonProcess.stdout.on('data', (data) => console.log(`stdout: ${data}`));
  pythonProcess.stderr.on('data', (data) => console.error(`stderr: ${data}`));

  pythonProcess.on('close', (code) => {
    console.log(`Python server exited with code ${code}`);
  });

  pythonProcess.on('error', (err) => {
    console.error(`Failed to start Python server: ${err.message}`);
  });

  return pythonProcess;
}

// Create the Electron window
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    webPreferences: {
      nodeIntegration: true,
    },
  });

  // Load the Python server's web interface
  mainWindow.loadURL('http://localhost:8080');

  mainWindow.on('closed', () => {
    mainWindow = null;

    // Quit the app when the window is closed
    if (process.platform !== 'darwin') {
      app.quit();
    }
  });
}

// Check if the Python server is ready
function waitForServer(url, callback) {
  const interval = setInterval(() => {
    http.get(url, (res) => {
      if (res.statusCode === 200) {
        clearInterval(interval);
        callback();
      }
    }).on('error', () => {
      // Server not ready, keep retrying
    });
  }, 1000); // Check every second
}

// Electron app lifecycle
app.on('ready', () => {
  startPythonServer();

  // Wait for the Python server to be ready, then create the window
  waitForServer('http://localhost:8080', () => {
    createWindow();
  });
});

app.on('window-all-closed', () => {
  // For macOS, apps generally don't quit when all windows are closed

    app.quit();

});

app.on('quit', () => {
  if (pythonProcess) {
    pythonProcess.kill();
    console.log('Python process terminated.');
  }
});

// On macOS, quit the app when the dock icon is clicked and no windows are open
app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});