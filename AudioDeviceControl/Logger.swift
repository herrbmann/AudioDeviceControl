import Foundation

class Logger {

    static let shared = Logger()

    private init() {}

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()

    func log(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] \(message)")
    }
}
