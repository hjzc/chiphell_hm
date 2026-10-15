
import {
  AppStorageV2,
} from '@kit.ArkUI';
import { getDBManager } from '../common/DBManager';
import { env } from '../Storage/ZjEnv';
import { ZjStorage } from '../Storage/ZjStorage';
import { common } from '@kit.AbilityKit';
import { ToastUtil } from '../utils/ToastUtil';
import { AppUtil } from '../utils/AppUtil';


@CustomDialog
struct CustomInputDialog {
  controller?: CustomDialogController;
  textController: TextInputController = new TextInputController();
  @State inputValue: string = "";


  result: (user:string | null)=>void = (user:string | null)=>{

  };

  aboutToAppear(): void {

  }
  build() {
    Column() {
      Text(' ')
        .width('900%')
      TextInput({controller:this.textController, placeholder: '请输入过滤用户名' })
        .width('90%')
        .defaultFocus(true)
        //.enableKeyboardOnFocus(false) // 获焦时不触发键盘
        .border({ width: { left:1, top:1,right:1, bottom: 1 }, color: $r('sys.color.comp_divider') })
        .margin(10)
        .onChange((value: string) => {
          this.inputValue= value;
        })
      Row(){
        Blank()
        Button($r('app.string.btn_cancel'))
          .onClick(() => {
            this.textController.stopEditing();
            if (this.controller != undefined) {
              this.controller.close();
            }
          })
          .margin(20)
        Blank()
          .width('30%')
        Button($r('app.string.confirm'))
          .onClick(() => {
            this.textController.stopEditing();
            if (this.controller != undefined) {
              this.controller.close();
            }
            if (this.result!==undefined) {
              this.result(this.inputValue.trim());
            }

          })
          .margin(20)
        Blank()
      }
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .backgroundColor($r('sys.color.background_tertiary'))
  }
}


@ComponentV2
export  struct SiteFiltersPage {
  @Consumer('webPageStack') webPageStack: NavPathStack = new NavPathStack();
  @Local statusBarHeight: number = env.statusBarHeight;
  @Param storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomInputDialog(
      {
        result:(user: string|null)=>{
          if (user!= null && (user.length > 0) ) {
            this.addUser(user);
          }
        }
      }
    ),
    backgroundColor: $r('sys.color.background_tertiary'),
    backgroundBlurStyle: BlurStyle.Thin,
    backgroundEffect: {
      radius: 60,
      saturation: 0,
      brightness: 1,
      color: Color.White,
      blurOptions: { grayscale: [20, 20] }
    },
  })

  addUser(user:string):void {
    if (this.storage != undefined) {
      if (this.storage.containFilter(user)) {
        getDBManager().insertFilter(this.getUIContext().getHostContext() as common.UIAbilityContext, user).then(
          (value)=>{
              if(value){
                this.storage.addFilter(user);
                ToastUtil.showToast(this.getUIContext(),$r('app.string.do_success'));
              }else{
                ToastUtil.showToast(this.getUIContext(),$r('app.string.do_failed'));
              }
          }
        )
      }else{
        ToastUtil.showToast(this.getUIContext(),$r('app.string.do_already_exist'));
      }
    }
  }



  @Builder
  AddMenu(){
    Row() {
      Column() {
        Image($r('sys.media.ohos_ic_public_add'))
          .fillColor($r('sys.color.icon_primary'))
          .width(24)
          .height(24)
      }
      .width(40)
      .height(40)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ left: 8 })
      .borderRadius(20)
    }
    .height(56)
    .margin({ right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.dialogController != null) {
        this.dialogController.open();
      }
    })
  }

  @Builder
  startImage() {
    if(AppUtil.is2N1Device()){
      Image($r('app.media.user'))
        .fillColor($r('sys.color.icon_primary'))
        .width(40)
        .height(40)
        .padding({
          top: 8,
          left: 8,
          bottom: 8,
          right: 8
        })
    }else{
      Image($r('app.media.user'))
        .fillColor($r('sys.color.icon_primary'))
        .width(20)
        .height(20)
    }
  }

  @Builder
  endImage(item: string,event: (event: ClickEvent) => void) {
    if(AppUtil.is2N1Device()){
      Image($r('app.media.filter_del'))
        .fillColor(Color.Red)
        .width(40)
        .height(40)
        .padding({
          top: 8,
          left: 8,
          bottom: 8,
          right: 8
        })
        .onClick(event)
    }else{
      Image($r('app.media.filter_del'))
        .fillColor(Color.Red)
        .width(20)
        .height(20)
        .onClick(event)
    }
  }


  build() {
    NavDestination() {
      Column() {
        ForEach(this.storage.filterList, (item: string) => {
          Row() {
            Row(){
              this.startImage()
              Text(item)
                .textAlign(TextAlign.Center)
                .padding({left:8,right:12})
                .fontSize($r('sys.float.ohos_id_popup_text_font_size'))
            }
            .justifyContent(FlexAlign.Start)
            this.endImage(item,(event)=>{
              getDBManager().deleteFilter(this.getUIContext().getHostContext() as common.UIAbilityContext, item).then(
                (value)=>{
                  if(value){
                    this.storage.deleteFilter(item);
                    ToastUtil.showToast(this.getUIContext(),$r('app.string.do_success'));
                  }else{
                    ToastUtil.showToast(this.getUIContext(),$r('app.string.do_failed'));
                  }
                }
              )
            })
          }
          .width('100%')
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .border({ width: { bottom: 1 }, color: $r('sys.color.comp_divider') })

        },(item: string) => item)
      }
      .padding({ left: 24, right: 24 })
    }
    .menus( this.AddMenu() )
    .title($r('app.string.page_filters_title'))
    .backgroundColor($r('sys.color.background_primary'))
    //.border({ width: {  bottom: 1 }, color: $r('sys.color.comp_divider') })
    .margin({ top: this.getUIContext() ? this.getUIContext().px2vp(this.statusBarHeight) : 0 ,bottom:0 })
    .onBackPressed(()=>{
      return false;
    });
  }



}