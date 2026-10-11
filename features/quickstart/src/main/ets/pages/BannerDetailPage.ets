import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { BannerClass } from '../model/BannerClass';

@Component
export struct BannerDetailPage {
  @State bannerClass: BannerClass | null = null;
  controller: webview.WebviewController = new webview.WebviewController();
  @Consume('articlePathStack') articlePathStack: NavPathStack;

  aboutToAppear(): void {
    this.bannerClass = this.articlePathStack.getParamByName('bannerDetailPage')[0] as BannerClass;

    try {
      // 配置Web开启无线调试模式，指定TCP Socket的端口。
      // hdc fport tcp:9222 tcp:9222  # 添加端口映射
      // hdc fport ls                 # 验证映射状态:cite[1]:cite[2]
      // 下载微软edge 打开 edge://inspect/#devices 页面，调试
      webview.WebviewController.setWebDebuggingAccess(true,9222);
    } catch (error) {
      console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    }

  }

  build() {
    NavDestination() {
      Column() {
        Web({
          src: this.bannerClass?.url,
          controller: this.controller
        })
          .darkMode(WebDarkMode.Auto)
          .domStorageAccess(true)
          .zoomAccess(true)
          .fileAccess(true)
          .mixedMode(MixedMode.All)
          .javaScriptAccess(true)
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}