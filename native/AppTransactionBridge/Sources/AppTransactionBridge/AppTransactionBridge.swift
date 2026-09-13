import Foundation
import StoreKit

/// Bridges StoreKit 2's Swift-only, `async` `AppTransaction.shared` API to an
/// Objective-C-compatible completion-handler surface that .NET-for-iOS can bind. Swift
/// automatically generates an Objective-C-compatible completion-handler variant of this method
/// because it's `@objc`-visible and its signature uses only ObjC-bridgeable types.
@objc public class AppTransactionBridge: NSObject {
    /// Returns StoreKit's raw `AppTransaction.Environment` value ("Production", "Sandbox", or
    /// "Xcode"), or nil if unavailable, unverified, or running below the minimum OS version.
    @objc public static func getEnvironment(completion: @escaping (String?) -> Void) {
        if #unavailable(iOS 16.0, macOS 13.0) {
            completion(nil)
            return
        }

        Task {
            let result: VerificationResult<AppTransaction>
            do {
                result = try await AppTransaction.shared
            } catch {
                completion(nil)
                return
            }

            switch result {
            case .verified(let transaction):
                completion(transaction.environment.rawValue)
            case .unverified:
                completion(nil)
            }
        }
    }
}
