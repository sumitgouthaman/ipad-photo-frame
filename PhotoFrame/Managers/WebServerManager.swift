import Foundation
import Combine
import Swifter

class WebServerManager: ObservableObject {
    static let shared = WebServerManager()
    
    let server = HttpServer()
    @Published var isRunning = false
    @Published var serverURL: String = "Not Running"
    
    func start() {
        do {
            // Serve the dashboard
            server["/"] = { request in
                return .ok(.htmlBody(self.dashboardHTML))
            }
            
            // Handle file upload
            server.POST["/upload"] = { request in
                let multipart = request.parseMultiPartFormData()
                
                for part in multipart {
                    if let filename = part.fileName {
                        let fileData = Data(part.body)
                        PhotoManager.shared.savePhoto(data: fileData, filename: filename)
                    }
                }
                
                return .ok(.text("Upload Successful"))
            }

            try server.start(8080)
            self.isRunning = true
            
            if let addresses = self.getWiFiAddress() {
                 let urls = addresses.components(separatedBy: "\n").map { "http://\($0):8080" }
                 self.serverURL = urls.joined(separator: "\n")
            } else {
                 self.serverURL = "http://localhost:8080"
            }
            
            print("Server started on \(self.serverURL)")
        } catch {
            print("Server start error: \(error)")
            self.isRunning = false
            self.serverURL = "Error starting server"
        }
    }
    
    func stop() {
        server.stop()
        self.isRunning = false
        self.serverURL = "Not Running"
    }
    
    // Simple helper to get IP address
    func getWiFiAddress() -> String? {
        var addresses = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        let address = String(cString: hostname)
                        if addrFamily == UInt8(AF_INET) {
                             addresses.append(address)
                        } else if addrFamily == UInt8(AF_INET6) {
                            // IPv6 usually needs brackets for URL
                            addresses.append("[\(address)]")
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return addresses.isEmpty ? nil : addresses.joined(separator: "\n")
    }
    
    var dashboardHTML: String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Photo Frame Uploader</title>
            <style>
                body { font-family: -apple-system, system-ui, sans-serif; padding: 20px; max-width: 800px; margin: 0 auto; text-align: center; }
                .upload-area { border: 2px dashed #ccc; padding: 40px; border-radius: 10px; margin-top: 20px; cursor: pointer; }
                .upload-area:hover { border-color: #007aff; background: #f0f8ff; }
                h1 { margin-bottom: 10px; }
            </style>
        </head>
        <body>
            <h1>iPad Photo Frame</h1>
            <p>Upload photos to your frame.</p>
            
            <div class="upload-area" id="drop-zone">
                <p>Drag & Drop photos or folders here or click to select</p>
                <input type="file" id="fileElem" multiple accept="image/*" style="display:none">
            </div>

            <div id="status" style="margin-top: 20px;"></div>

            <script>
                let dropZone = document.getElementById('drop-zone');
                let fileElem = document.getElementById('fileElem');
                let status = document.getElementById('status');
                
                dropZone.onclick = () => fileElem.click();
                
                dropZone.ondragover = (e) => {
                    e.preventDefault();
                    dropZone.style.borderColor = '#007aff';
                };
                
                dropZone.ondragleave = () => {
                   dropZone.style.borderColor = '#ccc';
                };

                dropZone.ondrop = async (e) => {
                    e.preventDefault();
                    dropZone.style.borderColor = '#ccc';
                    
                    let items = e.dataTransfer.items;
                    if (items) {
                        let files = [];
                        let queue = [];
                        
                        // Enqueue initial items
                        for (let i = 0; i < items.length; i++) {
                            let item = items[i];
                            if (item.kind === 'file') {
                                let entry = item.webkitGetAsEntry ? item.webkitGetAsEntry() : null;
                                if (entry) {
                                    queue.push(entry);
                                } else {
                                     // Fallback for non-entry support
                                    let file = item.getAsFile();
                                    if (file) files.push(file);
                                }
                            }
                        }
                        
                        await processQueue(queue, files);
                        if (files.length > 0) {
                            uploadFiles(files);
                        } else {
                            status.innerHTML = "No valid files found.";
                        }
                    } else {
                        // Use DataTransfer interface to access the file(s)
                        uploadFiles(e.dataTransfer.files);
                    }
                };
                
                async function processQueue(queue, fileList) {
                    while (queue.length > 0) {
                        let entry = queue.shift();
                        if (entry.isFile) {
                            await new Promise(resolve => {
                                entry.file(file => {
                                    fileList.push(file);
                                    resolve();
                                }, err => resolve());
                            });
                        } else if (entry.isDirectory) {
                            let reader = entry.createReader();
                            // readEntries returns batches (usually 100), so we must read until empty
                            let entries = await new Promise(resolve => {
                                let allEntries = [];
                                function read() {
                                    reader.readEntries(batch => {
                                        if (batch.length > 0) {
                                            allEntries.push(...batch);
                                            read();
                                        } else {
                                            resolve(allEntries);
                                        }
                                    }, err => resolve(allEntries));
                                }
                                read();
                            });
                            
                            for (let i = 0; i < entries.length; i++) {
                                queue.push(entries[i]);
                            }
                        }
                    }
                }
                
                fileElem.onchange = (e) => {
                    uploadFiles(e.target.files);
                };
                
                function uploadFiles(files) {
                    let validFiles = [];
                    // Regex for common image formats (case insensitive)
                    let imageRegex = /\\.(jpg|jpeg|png|gif|webp|heic|bmp)$/i;
                    
                    let log = document.getElementById('log');
                    if (!log) {
                        let logContainer = document.createElement('div');
                        logContainer.style.textAlign = 'left';
                        logContainer.style.marginTop = '20px';
                        logContainer.style.maxHeight = '300px';
                        logContainer.style.overflowY = 'auto';
                        logContainer.style.border = '1px solid #eee';
                        logContainer.style.padding = '10px';
                        
                        let header = document.createElement('h3');
                        header.innerText = "Upload Log";
                        logContainer.appendChild(header);
                        
                        log = document.createElement('ul');
                        log.id = 'log';
                        log.style.listStyleType = 'none';
                        log.style.padding = '0';
                        logContainer.appendChild(log);
                        
                        document.body.appendChild(logContainer);
                    }
                    
                    // Clear previous log if needed or keep appending? Let's clear for fresh batch
                    log.innerHTML = '';
                    
                    for (let i = 0; i < files.length; i++) {
                        if (imageRegex.test(files[i].name)) {
                             validFiles.push(files[i]);
                        } else {
                            addLog(files[i].name, 'Skipped (Not an image)', 'orange');
                        }
                    }
                    
                    if (validFiles.length === 0) {
                        status.innerHTML = "No valid image files found to upload.";
                        return;
                    }

                    status.innerHTML = "Starting upload of " + validFiles.length + " files...";
                    uploadNext(validFiles, 0);
                }
                
                function uploadNext(files, index) {
                    if (index >= files.length) {
                         status.innerHTML = "All uploads finished!";
                         return;
                    }
                    
                    let file = files[index];
                    let li = addLog(file.name, 'Uploading...', 'blue');
                    
                    let formData = new FormData();
                    formData.append('files[]', file, file.name);
                    
                    fetch('/upload', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => {
                        if (response.ok) {
                            updateLog(li, 'Success', 'green');
                        } else {
                            updateLog(li, 'Failed', 'red');
                        }
                        // Progress
                        status.innerHTML = "Uploaded " + (index + 1) + " of " + files.length;
                        // Next
                        uploadNext(files, index + 1);
                    })
                    .catch(error => {
                        updateLog(li, 'Error: ' + error.message, 'red');
                        uploadNext(files, index + 1);
                    });
                }
                
                function addLog(filename, message, color) {
                    let log = document.getElementById('log');
                    let li = document.createElement('li');
                    li.style.borderBottom = '1px solid #f0f0f0';
                    li.style.padding = '5px 0';
                    li.innerHTML = `<strong>${filename}</strong>: <span style="color:${color}">${message}</span>`;
                    log.appendChild(li);
                    return li;
                }
                
                function updateLog(li, message, color) {
                    // Update the span inside the li
                    let span = li.querySelector('span');
                    if (span) {
                        span.style.color = color;
                        span.innerText = message;
                    }
                }
            </script>
        </body>
        </html>
        """
    }
}
