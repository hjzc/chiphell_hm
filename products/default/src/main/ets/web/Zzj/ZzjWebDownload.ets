import { webview } from '@kit.ArkWeb';

export  interface  ZzjWebDownload {
  setWebviewController(controller: webview.WebviewController): void;
  onFileDownloadStart?(item: webview.WebDownloadItem,url: string,guid:string,filename:string,savePath:string): boolean;
  onFileDownloadProgress?(item: webview.WebDownloadItem,url: string,guid:string,filename:string,progress:number): boolean;
  onFileDownloadFinished?(item: webview.WebDownloadItem,failed:boolean): boolean;
}