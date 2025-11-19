import Foundation
import Combine
import AppKit

struct UpdateInfo {
    let latestVersion: String
    let releaseURL: String
    let releaseNotes: String?
}

enum UpdateCheckResult {
    case upToDate
    case updateAvailable(UpdateInfo)
}

final class UpdateChecker: ObservableObject {
    
    static let shared = UpdateChecker()
    
    @Published var updateStatus: UpdateCheckResult?
    @Published var isChecking = false
    
    private let githubRepo = "herrbmann/AudioDeviceControl"
    private let githubAPIURL = "https://api.github.com/repos/herrbmann/AudioDeviceControl/releases/latest"
    
    private init() {}
    
    // MARK: - Current Version
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    // MARK: - Check for Updates
    
    func checkForUpdates(force: Bool = false) {
        // Skip if already checking
        guard !isChecking else { return }
        
        // Skip if disabled
        guard UpdateStore.shared.isUpdateCheckEnabled() else {
            print("🔕 Update check disabled by user")
            return
        }
        
        // Skip if checked recently (unless forced)
        if !force {
            if let lastCheck = UpdateStore.shared.getLastCheckDate(),
               Date().timeIntervalSince(lastCheck) < 86400 { // 24 hours
                print("⏭️ Update check skipped (checked recently)")
                return
            }
        }
        
        isChecking = true
        print("🔍 Checking for updates...")
        
        guard let url = URL(string: githubAPIURL) else {
            isChecking = false
            print("❌ Update check: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isChecking = false
                
                if let error = error {
                    // Check if it's a network error (no internet, DNS failure, etc.)
                    let nsError = error as NSError
                    if nsError.domain == NSURLErrorDomain {
                        // Network errors: silently ignore (no internet, DNS issues, etc.)
                        print("⚠️ Update check skipped (network error):", error.localizedDescription)
                        // Don't set updateStatus - just silently fail
                        return
                    }
                    // Other errors: log but don't show to user
                    print("❌ Update check error:", error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("⚠️ Update check: Invalid response")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    print("⚠️ Update check HTTP error:", httpResponse.statusCode)
                    // Don't set error status for HTTP errors - just log
                    return
                }
                
                guard let data = data else {
                    print("⚠️ Update check: No data received")
                    return
                }
                
                self.parseReleaseData(data)
            }
        }.resume()
    }
    
    // MARK: - Parse Release Data
    
    private func parseReleaseData(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("⚠️ Update check: Invalid JSON response")
                return
            }
            
            guard let tagName = json["tag_name"] as? String else {
                print("⚠️ Update check: No tag_name in response")
                return
            }
            
            guard let htmlURL = json["html_url"] as? String else {
                print("⚠️ Update check: No html_url in response")
                return
            }
            
            let body = json["body"] as? String
            
            // Clean version string (remove "v" prefix if present)
            let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            
            // Compare versions
            if isVersionNewer(latestVersion, than: currentVersion) {
                print("✅ Update available: \(latestVersion) (current: \(currentVersion))")
                let updateInfo = UpdateInfo(
                    latestVersion: latestVersion,
                    releaseURL: htmlURL,
                    releaseNotes: body
                )
                updateStatus = .updateAvailable(updateInfo)
                UpdateStore.shared.setLastCheckDate(Date())
            } else {
                print("✅ App is up to date (\(currentVersion))")
                updateStatus = .upToDate
                UpdateStore.shared.setLastCheckDate(Date())
            }
            
        } catch {
            print("❌ JSON parsing error:", error)
            // Silently fail - don't set error status since it's not displayed in UI
        }
    }
    
    // MARK: - Version Comparison
    
    private func isVersionNewer(_ version1: String, than version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0
            
            if v1 > v2 { return true }
            if v1 < v2 { return false }
        }
        
        return false
    }
    
    // MARK: - Open Release Page
    
    func openReleasePage() {
        if case .updateAvailable(let info) = updateStatus {
            if let url = URL(string: info.releaseURL) {
                NSWorkspace.shared.open(url)
            }
        } else if let url = URL(string: "https://github.com/\(githubRepo)/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }
}

