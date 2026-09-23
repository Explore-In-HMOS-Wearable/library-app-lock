import { cryptoFramework } from "@kit.CryptoArchitectureKit";
import { userAuth } from "@kit.UserAuthenticationKit";

@Observed
export class AppLockController {
  public static init() {
    PersistentStorage.persistProp('isAppLockActive', false)
  }

  public static setIsActive(isActive: boolean) {
    AppStorage.set('isAppLockActive', isActive)
  }

  public static onBackground() {
    if (AppStorage.get('isAppLockActive')) {
      AppStorage.set('isAppLockLocked', true)
    }
  }

  public static isAppLockActive(): boolean {
    return AppStorage.get('isAppLockActive') ?? false
  }

  public static isAppLockAvailable(): boolean {
    try {
      // check if FACE is available
      userAuth.getAvailableStatus(
        userAuth.UserAuthType.FACE,
        userAuth.AuthTrustLevel.ATL3
      );
    } catch (e) {
      console.error(`No FACE: ${JSON.stringify(e)}`)
      try {
        // check if FINGERPRINT is available
        userAuth.getAvailableStatus(
          userAuth.UserAuthType.FINGERPRINT,
          userAuth.AuthTrustLevel.ATL3
        );
      } catch (e) {
        console.error(`No FINGERPRINT: ${JSON.stringify(e)}`)
        try {
          // check if PIN is available
          userAuth.getAvailableStatus(
            userAuth.UserAuthType.PIN,
            userAuth.AuthTrustLevel.ATL3
          );
        } catch (e) {
          console.error(`No PIN: ${JSON.stringify(e)}`)
          return false
        }
      }
    }
    return true
  }

  public static tryUnlock() {
    if (AppLockController.isAppLockActive() && AppLockController.isAppLockAvailable()) {
      try {
        const rand = cryptoFramework.createRandom();
        const randData: Uint8Array = rand.generateRandomSync(16)?.data;

        const authParam: userAuth.AuthParam = {
          challenge: randData,
          authType: [
            userAuth.UserAuthType.FACE,
            userAuth.UserAuthType.FINGERPRINT,
            userAuth.UserAuthType.PIN
          ],
          authTrustLevel: userAuth.AuthTrustLevel.ATL3,
        };

        let widgetParam: userAuth.WidgetParam = {
          title: 'AppLock 🔒',
        };

        let authInstance = userAuth.getUserAuthInstance(authParam, widgetParam);

        authInstance.on('result', {
          onResult(result: userAuth.UserAuthResult) {
            if (result.result === userAuth.UserAuthResultCode.SUCCESS) { // Success: Unlock the UI
              AppStorage.set('isAppLockLocked', false)
            } else { // Failure or user cancellation
              console.warn(`[AppLock] Authentication failed, error code: ${result.result}`);
            }
          }
        });

        authInstance.start();
      } catch (err) {
        console.error(`[AppLock] Failed to start authentication. Code: ${err.code}, message: ${err.message}`);
      }
    }
  }
}