using SyntaxCircus.Maui.Environments;

namespace SyntaxCircus.Maui.StoreKit;

/// <summary>
/// Implements <see cref="IAppTransactionEnvironmentProvider"/> (from
/// <c>SyntaxCircus.Maui.Environments</c>) via a native Swift shim wrapping StoreKit 2's
/// <c>AppTransaction.shared</c> - see this package's README for why a native shim is needed at
/// all (Apple's <c>AppTransaction</c> API is Swift-only and isn't bound by dotnet/macios the way
/// Objective-C-compatible StoreKit APIs are).
/// </summary>
public sealed class IosAppTransactionEnvironmentProvider : IAppTransactionEnvironmentProvider
{
    public Task<string?> GetEnvironmentAsync(CancellationToken cancellationToken = default)
    {
        var completionSource = new TaskCompletionSource<string?>();
        AppTransactionBridge.GetEnvironment(result => completionSource.TrySetResult(result?.ToString()));
        return completionSource.Task;
    }
}
