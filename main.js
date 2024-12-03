/**
 * Main Process for Open-WebUI Electron App
 * Author: Azad Djan
 * Website: https://azaddjan.com
 * Date: 2024-12-03
 * Description: Entry point for the Electron application.
 */

require('dotenv').config();
const { app, BrowserWindow } = require('electron');

// Set environment variables
process.env.WEBUI_AUTH = process.env.WEBUI_AUTH || "False";
process.env.ENABLE_LOGIN_FORM = process.env.ENABLE_LOGIN_FORM || "True";
process.env.WEBUI_NAME = process.env.WEBUI_NAME || "Open WebUI";

console.log("Environment variables loaded:");
console.log("WEBUI_AUTH:", process.env.WEBUI_AUTH);
console.log("ENABLE_LOGIN_FORM:", process.env.ENABLE_LOGIN_FORM);
console.log("WEBUI_NAME:", process.env.WEBUI_NAME);

let mainWindow;

// Define the server URL
const serverUrl = 'http://localhost:8080';

app.on('ready', () => {
    console.log("Loading URL:", serverUrl); // Debugging log

    mainWindow = new BrowserWindow({
        width: 1280,
        height: 720,
        webPreferences: {
            nodeIntegration: false,
        },
    });

    // Load the URL into the Electron app window
    mainWindow.loadURL('http://localhost:8080');

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
});

// Quit the app when all windows are closed
app.on('window-all-closed', () => {
    app.quit();
});