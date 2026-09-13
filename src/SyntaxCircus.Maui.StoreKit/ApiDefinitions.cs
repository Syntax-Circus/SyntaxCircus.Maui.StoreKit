using System;
using Foundation;
using ObjCRuntime;

namespace SyntaxCircus.Maui.StoreKit;

// Binds native/AppTransactionBridge's Objective-C-visible surface (see build-xcframework.sh and
// the README's "How this works" section). Internal: IosAppTransactionEnvironmentProvider is the
// package's actual public surface - this raw native binding is an implementation detail.
[Internal]
[BaseType(typeof(NSObject))]
interface AppTransactionBridge
{
    [Static]
    [Export("getEnvironmentWithCompletion:")]
    void GetEnvironment(Action<NSString?> completion);
}
