import Foundation

extension Bundle {
    static var appModule: Bundle {
        if let resourcesURL = Bundle.main.resourceURL {
            let bundleURL = resourcesURL.appendingPathComponent("ValetBar_ValetBar.bundle")
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        
        let bundleName = "ValetBar_ValetBar"
        if let bundleURL = Bundle.main.bundleURL.appendingPathComponent(bundleName + ".bundle") as URL?,
           let bundle = Bundle(url: bundleURL) {
            return bundle
        }
        
        return Bundle.main
    }
}
