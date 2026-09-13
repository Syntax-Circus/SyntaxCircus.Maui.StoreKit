import Foundation
import StoreKit

/// Bridges StoreKit 2's Swift-only, `async` `AppTransaction.shared` API to an
/// Objective-C-compatible completion-handler surface that .NET-for-iOS can bind. Swift
/// automatically generates an Objective-C-compatible completion-handler variant of this method
/// because it's `@objc`-visible and its signature uses only ObjC-bridgeable types.
// The explicit @objc(AppTransactionBridge) is required, not decorative: since this Swift module
// is also named "AppTransactionBridge" (same as the class), Swift's default ObjC name-mangling
// scheme (to avoid cross-module class name collisions) exposes the class under a mangled runtime
// name like "_TtC20AppTransactionBridge20AppTransactionBridge" instead of the clean
// "AppTransactionBridge" ApiDefinitions.cs's [BaseType(typeof(NSObject))] binding expects -
// producing a build-succeeds-but-app-link-fails "Undefined symbols ... _OBJC_CLASS_$_AppTransactionBridge"
// error with no compile-time indication of the mismatch. Verify with `nm -g libAppTransactionBridge.a`
// if this class is ever renamed.
@objc(AppTransactionBridge)
public class AppTransactionBridge: NSObject {
    /// Returns StoreKit's raw `AppTransaction.Environment` value ("Production", "Sandbox", or
    /// "Xcode"), or nil if unavailable, unverified, or running below the minimum OS version.
    @objc public static func getEnvironment(completion: @escaping (String?) -> Void) {
        // The #available check must live *inside* the Task closure, not in the outer function
        // body - Swift's availability refinement from an enclosing `if`/`guard` does not
        // propagate into a Task{} trailing closure, so referencing AppTransaction here would
        // otherwise fail to compile with "'AppTransaction' is only available in iOS 16.0 or newer"
        // even though the outer check already guards it at runtime.
        Task {
            guard #available(iOS 16.0, macOS 13.0, *) else {
                completion(nil)
                return
            }

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
