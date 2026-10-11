import { webview } from '@kit.ArkWeb';


@Component
export struct CourseLearning {
  private webviewController: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src:
      //'https://www.huawei.com',
      $rawfile('course_learning/index.html'),
        controller: this.webviewController })
        .domStorageAccess(true)
    }
  }
}