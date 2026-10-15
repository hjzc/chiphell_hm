import { logger } from "utils";
import { ZzjWebJsObject } from "./Zzj/ZzjWebJsObject";
import { JSONUtil } from "../utils/JSONUtil";
import { env } from "../Storage/ZjEnv";
/**
 * 加载简单网页
 */
export class SimpleWebJsObject extends ZzjWebJsObject {

  onEvent?:(event:number,param: string | undefined | null) =>void = (event:number,param: string | undefined | null )=>{

  };
  onHandleWebClientEvent(event:number , param: string | undefined | null|OnSslErrorEventReceiveEvent):void{
    //update
    if(event==-999 &&(param) && (param as OnSslErrorEventReceiveEvent)  ){
      let sslEv  = param as OnSslErrorEventReceiveEvent;
    }
  }
  sslBack():void {
    if(this.onEvent){
      this.onEvent(1, null);
    }
  }
  sslCancel():void {
    if(this.onEvent){
      this.onEvent(2, null);
    }
  }
  sslContinue():void {
    if(this.onEvent){
      this.onEvent(3, null);
    }
  }
  sslBypass():void {
    if(this.onEvent){
      this.onEvent(4, null);
    }
  }

}