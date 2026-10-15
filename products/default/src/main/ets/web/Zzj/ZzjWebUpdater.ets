import { AttributeUpdater } from '@kit.ArkUI';

export class ZzjWebUpdater extends AttributeUpdater<WebAttribute> {

  //首次绑定时触发initializeModifier方法，进行属性初始化
  initializeModifier(instance: WebAttribute): void {
    // instance.backgroundColor(Color.Transparent)
  }

}