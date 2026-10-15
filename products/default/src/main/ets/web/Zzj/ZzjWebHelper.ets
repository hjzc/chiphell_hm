import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { ZzjWebUtils } from './ZzjWebUtils';
import { logger } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * ArkWeb工具类
 */
export class ZzjWebHelper {

  static debug: boolean = false; //是否是debug模式

  /**
   * 初始化
   * @param UIAbilityContext
   * @param debug 是否是debug模式
   */
  static init(context: common.UIAbilityContext, debug: boolean = false) {
    ZzjWebHelper.debug = debug;

    //Web组件开启BFCache
    let features = new webview.BackForwardCacheSupportedFeatures();
    features.nativeEmbed = true;
    features.mediaTakeOver = true;
    webview.WebviewController.enableBackForwardCache(features);

    webview.WebviewController.initializeWebEngine();
    if(debug){
      try {
        webview.WebviewController.setWebDebuggingAccess(debug, 9222);
        // // 允许第三方cookies
        // webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(true);
        // webview.WebCookieManager.putAcceptCookieEnabled(true);
        //
        // let value = webview.WebCookieManager.fetchCookieSync('https://www.chiphell.com');
        // webview.WebCookieManager.configCookieSync('http://static.chiphell.com',
        //   value + '; PATH=/; Max-Age=900000; HttpOnly; SameSite=Lax');

      } catch (error) {
        logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
      }
    }
   else{
     webview.WebviewController.setWebDebuggingAccess(false);
   }
   ZzjWebUtils.onAbilityLifecycle(context);

  }

  //设置Web组件可以缓存的最大数量为10，每个页面在缓存中停留300s。在web页面 attach 后  build之后执行
  static  setBFCacheOptionsToController(controller:webview.WebviewController):void {
    let options = new webview.BackForwardCacheOptions();
    options.size = 10;
    options.timeToLive = 300;
    try {
      controller.setBackForwardCacheOptions(options);
    } catch (error) {
      //初始化错误。WebviewController必须与Web组件相关联
      logger.error(`setBFCacheOptions: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    }
  }




  /**
   * 预连接url，在加载url之前调用此API。
   * @param url 预连接的url。
   * @param preconnectable 是否进行预连接。如果preconnectable为true，则对url进行dns解析，socket建链预连接；如果preconnectable为false，则不做任何预连接操作。
   * @param numSockets 要预连接的socket数。socket数目连接需要大于0，最多允许6个连接。
   */
  static prepareForPageLoad(url: string | string[], preconnectable: boolean = true, numSockets: number = 2) {
    if (Array.isArray(url)) {
      url.forEach((item) => webview.WebviewController.prepareForPageLoad(item, preconnectable, numSockets))
    } else {
      webview.WebviewController.prepareForPageLoad(url, preconnectable, numSockets);
    }
  }


  /**
   * 异步执行JavaScript脚本，并通过Promise方式返回脚本执行的结果。runJavaScript需要在loadUrl完成后，比如onPageEnd中调用。
   * @param webController
   * @param script JavaScript脚本
   * @returns
   */
  static async runJavaScript(webController: webview.WebviewController, script: string): Promise<string> {
    return webController.runJavaScript(script);
  }

  /**
   * 异步执行JavaScript脚本，并通过Promise方式返回脚本执行的结果。runJavaScriptExt需要在loadUrl完成后，比如onPageEnd中调用。
   * @param webController
   * @param script JavaScript脚本。
   * @returns
   */
  static async runJavaScriptExt(webController: webview.WebviewController, script: string | ArrayBuffer): Promise<webview.JsMessageExt> {
    return webController.runJavaScriptExt(script);
  }

  /**
   * 异步执行JavaScript方法
   * @param webController
   * @param funName 方法名
   * @param param 方法参数
   * @returns
   */
  static async runJavaScriptFun(webController: webview.WebviewController, funName: string, param?: string): Promise<string> {
    if (param) {
      return ZzjWebHelper.runJavaScript(webController, `${funName}('${param}')`);
    } else {
      return ZzjWebHelper.runJavaScript(webController, `${funName}()`);
    }
  }


  /**
   * 以Promise方式异步获取指定url对应cookie的值。
   * @param url 要获取的cookie所属的url，建议使用完整的url。
   * @returns
   */
  static async fetchCookie(url: string): Promise<string> {
    return await webview.WebCookieManager.fetchCookie(url);
  }

  /**
   * 获取指定url对应cookie的值。
   * @param url 要获取的cookie所属的url，建议使用完整的url。
   * @param incognito true表示获取隐私模式下webview的内存cookies，false表示正常非隐私模式下的cookies。
   * @returns
   */
  static fetchCookieSync(url: string, incognito?: boolean): string {
    return webview.WebCookieManager.fetchCookieSync(url, incognito);
  }


  /**
   * 以异步Promise方式为指定url设置单个cookie的值。
   * @param url 要设置的cookie所属的url，建议使用完整的url。
   * @param value 要设置的cookie的值。
   */
  static async configCookie(url: string, value: string): Promise<void> {
    return await webview.WebCookieManager.configCookie(url, value);
  }

  /**
   * 为指定url设置单个cookie的值。
   * @param url 要设置的cookie所属的url，建议使用完整的url。
   * @param value 要设置的cookie的值。
   * @param incognito true表示设置隐私模式下对应url的cookies，false表示设置正常非隐私模式下对应url的cookies。
   */
  static configCookieSync(url: string, value: string, incognito?: boolean) {
    webview.WebCookieManager.configCookieSync(url, value, incognito);
  }


  /**
   * 将当前存在内存中的cookie以Promise方法异步保存到磁盘中。
   * @returns
   */
  static async saveCookieAsync(): Promise<void> {
    return await webview.WebCookieManager.saveCookieAsync();
  }


  /**
   * 设置WebCookieManager实例是否拥有发送和接收cookie的权限。
   * @param accept 设置是否拥有发送和接收cookie的权限，默认为true。
   */
  static putAcceptCookieEnabled(accept: boolean): void {
    webview.WebCookieManager.putAcceptCookieEnabled(accept);
  }

  /**
   * 获取WebCookieManager实例是否拥有发送和接收cookie的权限。
   * @returns
   */
  static isCookieAllowed(): boolean {
    return webview.WebCookieManager.isCookieAllowed();
  }


  /**
   * 设置WebCookieManager实例是否拥有发送和接收第三方cookie的权限。
   * @param accept 设置是否拥有发送和接收第三方cookie的权限，默认为false。
   */
  static putAcceptThirdPartyCookieEnabled(accept: boolean): void {
    webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(accept);
  }

  /**
   * 获取WebCookieManager实例是否拥有发送和接收第三方cookie的权限。
   * @returns
   */
  static isThirdPartyCookieAllowed(): boolean {
    return webview.WebCookieManager.isThirdPartyCookieAllowed();
  }


  /**
   * 获取是否存在cookie。
   * @param incognito true表示隐私模式下查询是否存在cookies，false表示正常非隐私模式下查询是否存在cookies。
   * @returns
   */
  static existCookie(incognito?: boolean): boolean {
    return webview.WebCookieManager.existCookie(incognito);
  }


  /**
   * 异步promise方式清除所有cookie。
   * @returns
   */
  static async clearAllCookies(): Promise<void> {
    return await webview.WebCookieManager.clearAllCookies();
  }

  /**
   * 清除所有cookie。
   * @param incognito true表示清除隐私模式下webview的所有内存cookies，false表示清除正常非隐私模式下的持久化cookies。
   */
  static clearAllCookiesSync(incognito?: boolean): void {
    webview.WebCookieManager.clearAllCookiesSync(incognito);
  }


  /**
   * 异步promise方式清除所有会话cookie。
   * @returns
   */
  static async clearSessionCookie(): Promise<void> {
    return await webview.WebCookieManager.clearSessionCookie();
  }

  /**
   * 清除所有会话cookie。
   */
  static clearSessionCookieSync(): void {
    webview.WebCookieManager.clearSessionCookieSync();
  }


  /**
   * 以Promise方式异步获取当前使用Web SQL数据库的所有源的信息。
   * @returns
   */
  static async getOrigins(): Promise<Array<webview.WebStorageOrigin>> {
    return await webview.WebStorage.getOrigins();
  }

  /**
   * 以Promise方式异步获取指定源的Web SQL数据库的存储配额，配额以字节为单位。
   * @param origin 指定源的字符串索引
   * @returns
   */
  static async getOriginQuota(origin: string): Promise<number> {
    return await webview.WebStorage.getOriginQuota(origin);
  }

  /**
   * 以Promise方式异步获取指定源的Web SQL数据库的存储量，存储量以字节为单位。
   * @param origin 指定源的字符串索引
   * @returns
   */
  static async getOriginUsage(origin: string): Promise<number> {
    return await webview.WebStorage.getOriginUsage(origin);
  }


  /**
   * 清除指定源所使用的存储。
   * @param origin 指定源的字符串索引，来自于getOrigins。
   */
  static deleteOrigin(origin: string): void {
    webview.WebStorage.deleteOrigin(origin);
  }

  /**
   * 清除Web SQL数据库当前使用的所有存储。
   * @param incognito 清除Web SQL数据库当前使用的所有存储。
   */
  static deleteAllData(incognito?: boolean): void {
    webview.WebStorage.deleteAllData(incognito);
  }


  /**
   * 检索给定主机和域的HTTP身份验证凭据，该方法为同步方法。
   * @param host HTTP身份验证凭据应用的主机。
   * @param realm HTTP身份验证凭据应用的域。
   * @returns
   */
  static getHttpAuthCredentials(host: string, realm: string): Array<string> {
    return webview.WebDataBase.getHttpAuthCredentials(host, realm);
  }

  /**
   * 保存给定主机和域的HTTP身份验证凭据，该方法为同步方法。
   * @param host HTTP身份验证凭据应用的主机。
   * @param realm HTTP身份验证凭据应用的域。
   * @param username 用户名。
   * @param password 密码。
   */
  static saveHttpAuthCredentials(host: string, realm: string, username: string, password: string): void {
    webview.WebDataBase.saveHttpAuthCredentials(host, realm, username, password);
  }

  /**
   * 判断是否存在任何已保存的HTTP身份验证凭据，该方法为同步方法。存在返回true，不存在返回false。
   * @returns
   */
  static existHttpAuthCredentials(): boolean {
    return webview.WebDataBase.existHttpAuthCredentials();
  }

  /**
   * 清除所有已保存的HTTP身份验证凭据，该方法为同步方法。
   */
  static deleteHttpAuthCredentials(): void {
    webview.WebDataBase.deleteHttpAuthCredentials();
  }





}