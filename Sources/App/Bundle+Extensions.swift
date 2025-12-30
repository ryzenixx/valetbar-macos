import Foundation

extension Bundle {
    static var appModule: Bundle {
        // 1. Check for the bundle in the standard Resources directory (App Bundle)
        if let resourcesURL = Bundle.main.resourceURL {
            let bundleURL = resourcesURL.appendingPathComponent("ValetBar_ValetBar.bundle")
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        
        // 2. Check for the bundle adjacent to the executable (CLI / Fallback)
        let bundleName = "ValetBar_ValetBar"
        if let bundleURL = Bundle.main.bundleURL.appendingPathComponent(bundleName + ".bundle") as URL?,
           let bundle = Bundle(url: bundleURL) {
            return bundle
        }
        
        // 3. Fallback to main bundle (if resources are somehow merged)
        return Bundle.main
    }
}
