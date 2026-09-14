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
    // AppTransaction.shared can be slow to resolve shortly after a fresh TestFlight/App Store
    // install - it may need to contact Apple's servers for a freshly signed transaction - and the
    // native completion callback has no cancellation or deadline of its own, so without a timeout
    // here a slow/hung native call would block distribution-channel detection (and therefore the
    // app's loading screen) indefinitely.
    private static readonly TimeSpan NativeCallTimeout = TimeSpan.FromSeconds(8);

    public async Task<string?> GetEnvironmentAsync(CancellationToken cancellationToken = default)
    {
        var completionSource = new TaskCompletionSource<string?>();
        AppTransactionBridge.GetEnvironment(result => completionSource.TrySetResult(result?.ToString()));

        var delay = Task.Delay(NativeCallTimeout, cancellationToken);
        var completed = await Task.WhenAny(completionSource.Task, delay).ConfigureAwait(false);
        cancellationToken.ThrowIfCancellationRequested();
        if (completed == delay)
        {
            throw new TimeoutException("Timed out waiting for AppTransactionBridge.GetEnvironment to complete.");
        }

        return await completionSource.Task.ConfigureAwait(false);
    }
}
