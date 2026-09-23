import { AppLockController } from "../../../../Index";
import { display } from "@kit.ArkUI";

@Component
export struct AppLock {
  @StorageLink('isAppLockActive') private isAppLockActive: boolean = true;
  @StorageLink('isAppLockLocked') private isAppLockLocked: boolean = this.isAppLockActive;
  @BuilderParam private page: () => void

  aboutToAppear(): void {
    AppLockController.tryUnlock()
  }

  build() {
    if (this.isAppLockActive && this.isAppLockLocked && AppLockController.isAppLockAvailable()) {
      Column({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.lock'))
          .fontSize(this.getUIContext().px2vp(display.getDefaultDisplaySync().width) / 2)
          .fontColor([$r('sys.color.ohos_id_color_foreground')])

        Button() {
          SymbolGlyph($r('sys.symbol.lock_open'))
            .fontColor([$r('sys.color.ohos_id_color_foreground')])
        }.size({ width: '100%', height: 50 })
        .onClick(() => {
          AppLockController.tryUnlock()
        })
      }
      .size({ width: '100%', height: '100%' })
      .justifyContent(FlexAlign.Center)
      .padding(16)
    } else {
      this.page()
    }
  }
}
