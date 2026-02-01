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
            self.serverURL = "http://\(self.getWiFiAddress() ?? "localhost"):8080"
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
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" { // Usually WiFi
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
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
                <p>Drag & Drop photos here or click to select</p>
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

                dropZone.ondrop = (e) => {
                    e.preventDefault();
                    dropZone.style.borderColor = '#ccc';
                    handleFiles(e.dataTransfer.files);
                };
                
                fileElem.onchange = (e) => {
                    handleFiles(e.target.files);
                };
                
                function handleFiles(files) {
                    status.innerHTML = "Uploading " + files.length + " files...";
                    let formData = new FormData();
                    for (let i = 0; i < files.length; i++) {
                        formData.append('files[]', files[i], files[i].name);
                    }
                    
                    fetch('/upload', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => response.text())
                    .then(data => {
                        status.innerHTML = "Upload Complete!";
                        setTimeout(() => status.innerHTML = "", 3000);
                    })
                    .catch(() => {
                        status.innerHTML = "Upload Failed.";
                    });
                }
            </script>
        </body>
        </html>
        """
    }
}
