# Frontend API (ao_module.js)

The `ao_module.js` wrapper provides the client-side API for ArozOS webapps. It handles float window control, file operations, backend AGI calls, and utility functions.

## Setup

```html
<script src="../script/jquery.min.js"></script>
<script src="../script/ao_module.js"></script>
```

jQuery must be imported first. **Use relative paths** — absolute paths break internal path resolution.

## Global Variables

```javascript
ao_module_virtualDesktop  // boolean — true when running in web desktop mode
ao_module_windowID        // current float window ID
ao_module_parentID        // parent window ID (if created by another app)
ao_module_callback        // callback function name in parent (string)
ao_root                   // relative path to ArozOS web root (e.g. "../")
```

---

## AGI Backend Calls

### ao_module_agirun(scriptpath, data, callback, failedcallback, timeout)

Execute a backend AGI script. Parameters are passed as global variables in the script.

```javascript
ao_module_agirun("MyApp/backend/api.js", {
    name: "Neon"
}, function(resp) {
    console.log(resp);
}, function() {
    console.log("Failed");
}, 3000);
```

See [Apps and Subservices](apps-and-subservices.md) for backend script examples.

---

## Float Window Control

### Creating Windows

#### ao_module_newfw(config)

Open a new float window.

```javascript
// Minimal
ao_module_newfw({
    url: "MyApp/index.html",
    title: "My App",
    appicon: "MyApp/img/icon.png"
});

// Full options
ao_module_newfw({
    url: "MyApp/index.html",
    uid: "custom-uuid",
    width: 1024,
    height: 768,
    appicon: "MyApp/img/icon.png",
    title: "My App",
    left: 100,
    top: 100,
    "background-color": "#fcfcfc",
    parent: ao_module_windowID,
    callback: "onChildResponse"
});
```

When `parent` and `callback` are set, the child window can send data back via `ao_module_parentCallback()`.

### Window Properties

| Function | Description |
|----------|-------------|
| `ao_module_setFixedWindowSize()` | Make window non-resizable |
| `ao_module_setResizableWindowSize()` | Make window resizable (default) |
| `ao_module_setWindowSize(width, height)` | Resize the window |
| `ao_module_setWindowTitle(title)` | Update window title (or `document.title` outside desktop mode) |
| `ao_module_focus()` | Bring window to front |
| `ao_module_setTopMost()` | Pin window above all others |
| `ao_module_unsetTopMost()` | Unpin from top-most layer |

### Single Instance

#### ao_module_makeSingleInstance()

Check if another window with the same path exists. If yes, transfer the current hash to it and close the current window. Returns `false` if no other instance was found.

#### ao_module_getInstanceByPath(path)

Get the DOM element of another float window with the given path. Returns `null` if not found.

```javascript
let other = ao_module_getInstanceByPath("NotepadA/index.html");
```

### Closing

#### ao_module_close()

Close the current float window. Override this to add save-before-close logic:

```javascript
ao_module_close = function() {
    if (documentIsSaved()) {
        ao_module_closeHandler();
    } else {
        alert("Please save before closing");
    }
}
```

#### ao_module_closeHandler()

The underlying close implementation. Call this from your custom `ao_module_close()` override when you're ready to actually close.

### Parent-Child Communication

#### ao_module_hasParentCallback()

Returns `true` if this window has a living parent with a callback set.

#### ao_module_parentCallback(data)

Send string data back to the parent window's callback function. Use `JSON.stringify()` for objects.

```javascript
if (ao_module_hasParentCallback()) {
    ao_module_parentCallback(JSON.stringify({ result: "done" }));
    ao_module_close();
}
```

---

## File Operations

### Cloud File Selector

#### ao_module_openFileSelector(callback, root, type, allowMultiple, options)

Open ArozOS's built-in file picker for cloud virtual drives.

```javascript
ao_module_openFileSelector(function(files) {
    files.forEach(f => console.log(f.filename, f.filepath));
}, "user:/Desktop", "file", true, {
    defaultName: "newfile.txt",     // for "new" type
    filter: ["mp3", "flac", "wav"]  // extension filter
});
```

| Type | Selectable |
|------|-----------|
| `"file"` | Files only |
| `"folder"` | Folders only |
| `"all"` | Files or folders |
| `"new"` | Create new file (requires `options.defaultName`) |

### Local File Selector

#### ao_module_selectFiles(callback, fileType, accept, allowMultiple)

Open the browser's native file picker for local device files.

```javascript
ao_module_selectFiles(function(files) {
    console.log(files);
}, "file", ".jpg,.png", true);
```

### File Navigation

#### ao_module_openPath(path, filename)

Open a File Manager instance at the given path. If `filename` is provided, it will be highlighted.

```javascript
ao_module_openPath("user:/Desktop", "music.mp3");
```

### Input Files (Embedded Mode)

#### ao_module_loadInputFiles()

When a file is opened with your app (embedded mode), this returns the file list passed by File Manager. Returns `null` if no files were passed.

```javascript
var files = ao_module_loadInputFiles();
if (files != null) {
    files.forEach(f => console.log(f.filename, f.filepath));
}
```

Returned structure:
```json
[
    { "filename": "test.jpg", "filepath": "user:/Desktop/test.jpg" },
    { "filename": "test2.jpg", "filepath": "user:/Desktop/test2.jpg" }
]
```

### File Upload

#### ao_module_uploadFile(file, targetPath, callback, progressCallback, failedcallback)

Upload a file via XHR.

```javascript
ao_module_uploadFile(fileObject, "user:/Desktop/", function(resp) {
    console.log("Done:", resp);
}, function(percent) {
    console.log(percent + "% uploaded");
}, function(status) {
    console.log("Failed:", status);
});
```

For large files, use the WebSocket upload endpoint at `/system/file_system/lowmemUpload`. See [the upstream examples](https://github.com/aroz-online/ArozOS-Developers) for the chunked upload protocol.

---

## Media Endpoints

These are HTTP endpoints, not ao_module functions, but commonly used in webapps.

| Endpoint | Description |
|----------|-------------|
| `GET /media?file=user:/path` | Stream a file (no download headers) |
| `GET /media?file=user:/path&download=true` | Stream with download headers |
| `GET /media/download/?file=user:/path` | Force download in new tab |
| `GET /media/getMime/?file=user:/path` | Get MIME type as text/plain |
| `GET /media/transcode?file=user:/path&res=720p` | Realtime video transcode (requires ffmpeg). Resolution: `360p`, `720p`, `1080p`, or empty for source |

---

## Storage Utilities

### ao_module_storage

```javascript
ao_module_storage.setStorage(moduleName, key, value);  // Store config on server
ao_module_storage.loadStorage(moduleName, key);         // Load config from server
```

---

## Utility Functions

### ao_module_utils

| Function | Description |
|----------|-------------|
| `getRandomUID()` | Random UUID from timestamp |
| `getIconFromExt(ext)` | Icon tag for a file extension |
| `stringToBlob(text, mime)` | Convert string to Blob |
| `blobToFile(blob, filename, mime)` | Convert Blob to File |
| `getDropFileInfo(dropEvent)` | Get filepath/filename from drag-drop |
| `readFileFromFileObject(file, success, failed)` | Read File object as text |
| `durationConverter(seconds)` | Seconds → "X Days Y Hours Z Minutes" |
| `formatBytes(bytes, decimals)` | Bytes → "1.5 MB" |
| `timeConverter(unix_timestamp)` | Unix timestamp → readable string |
| `getWebSocketEndpoint()` | Build WebSocket URL root (e.g. `wss://host:port/`) |
| `objectToAttr(object)` | Object to DOM attribute string |
| `attrToObject(attr)` | DOM attribute string to object |
