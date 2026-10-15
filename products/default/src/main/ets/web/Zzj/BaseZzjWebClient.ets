import { webview } from '@kit.ArkWeb';
import { ZzjWebClient } from './ZzjWebClient';
import { ZzjWebHelper } from './ZzjWebHelper';

/**
 * 默认的ArkWebClient
 */
export class BaseZzjWebClient implements ZzjWebClient {

  controller?: webview.WebviewController;

  setWebviewController(controller: webview.WebviewController): void {
    this.controller = controller;
  }

  /**
   * 异步执行JavaScript脚本，并通过Promise方式返回脚本执行的结果。runJavaScript需要在loadUrl完成后，比如onPageEnd中调用。
   * @param script JavaScript脚本
   * @returns
   */
  async runJavaScript(script: string): Promise<string> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScript(this.controller, script);
    }
    return '';
  }

  /**
   * 异步执行JavaScript脚本，并通过Promise方式返回脚本执行的结果。runJavaScriptExt需要在loadUrl完成后，比如onPageEnd中调用。
   * @param script JavaScript脚本。
   * @returns
   */
  async runJavaScriptExt(script: string | ArrayBuffer): Promise<webview.JsMessageExt> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScriptExt(this.controller, script);
    }
    return new webview.JsMessageExt();
  }

  /**
   * 异步执行JavaScript方法
   * @param funName 方法名
   * @param param 方法参数
   * @returns
   */
  async runJavaScriptFun(funName: string, param?: string): Promise<string> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScriptFun(this.controller, funName, param);
    }
    return '';
  }

  onBrowserDownloader?(url:string):boolean{
    let r:boolean=false;
    try {
      this.controller?.startDownload(url);
      r=true;
    } catch (error) {
      // TODO: Implement error handling.
    }
    return r;
  }


}