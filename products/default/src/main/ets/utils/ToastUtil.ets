
// import { promptAction } from '@kit.ArkUI';
// import { common } from "@kit.AbilityKit";
// //@ohos.arkui.UIContext

export  class  ToastUtil{

  static   showToast(uiContext:UIContext, message:string | Resource,duration:number = 2000){
    const prompt = uiContext.getPromptAction();
    try {
      prompt.showToast({
        message: message,
        duration: duration
      });
    } catch (error) {
      // TODO: Implement error handling.
      console.error("show to toast error is "+ JSON.stringify(error));
    }
  }




}

