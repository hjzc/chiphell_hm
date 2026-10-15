import { ToolBarV2ItemImage, ToolBarV2ItemText, ToolBarV2Item, ToolBarV2, ToolBarV2Modifier,
  LengthMetrics,
  ColorMetrics,
  DividerModifier,
  } from '@kit.ArkUI';

import { MPIType } from '../model/ToolBarMorePopModel';
import { AccessSiteType } from '../model/WebSite';
import { MorePopup } from './MorePopup';

@ComponentV2
export struct WebToolBar {
  @Local  toolbarList:  ToolBarV2Item[]  =[];

  //TODO:不增加连个参数，修改主题后 背景色没有被修改
  private toolBarModifier: ToolBarV2Modifier =
    new ToolBarV2Modifier().height(LengthMetrics.vp(52))
      .backgroundColor(ColorMetrics.resourceColor(Color.Transparent))
      .stateEffect(false);
  @Local dividerModifier: DividerModifier = new DividerModifier().height(0);
  @Local isShowPopup: boolean = false
  @Param accessSiteType :AccessSiteType = AccessSiteType.pc;

  //方法1
  @Event click: (index:number|MPIType) => void;

  //方法2 双向绑定，父组件 @Local clickIndex: number｜MPIType = 0;
  //@Param clickIndex: number｜MPIType = 0;
 // @Event $clickIndex: (index:number|MPIType) => void = (index: number|MPIType) => {};

  // onWillApplyTheme(theme: Theme) {
  //   logger.debug('WebToolBar onWillApplyTheme:');
  // }
  //
  // aboutToDisappear(): void {
  //   logger.debug('aboutToDisappear');
  // }

  aboutToAppear() {
    // this.toolbarList.push(new ToolBarV2Item({
    //   content: new ToolBarV2ItemText({ text: '' } ),
    //   icon: new ToolBarV2ItemImage({
    //     src: $r('app.media.arrow_left_to_line')
    //   }),
    //   action: () => {
    //     this.click(0);
    //   },
    // }))
    //
    // this.toolbarList.push(new ToolBarV2Item({
    //   content: new ToolBarV2ItemText({ text: '' } ),
    //   icon: new ToolBarV2ItemImage({
    //     src:   $r('sys.symbol.house')
    //   }),
    //   action: () => {
    //     this.click(1);
    //   },
    // }))
    //
    // this.toolbarList.push(new ToolBarV2Item({
    //   content: new ToolBarV2ItemText({ text: '' } ),
    //   icon: new ToolBarV2ItemImage({
    //     src: $r('sys.symbol.arrow_left')
    //   }),
    //   action: () => {
    //     this.click(2);
    //   },
    // }))
    //
    // this.toolbarList.push(new ToolBarV2Item({
    //   content: new ToolBarV2ItemText({ text: '' } ),
    //   icon: new ToolBarV2ItemImage({
    //     src:   $r('sys.symbol.arrow_clockwise')
    //   }),
    //   action: () => {
    //     this.click(3);
    //   },
    // }))
    //
    // this.toolbarList.push(new ToolBarV2Item({
    //   content: new ToolBarV2ItemText({ text: '' } ),
    //   icon: new ToolBarV2ItemImage({
    //     src: $r('sys.media.ohos_ic_public_more')
    //   }),
    //   action: () => {
    //     this.click(4);
    //   },
    // }))

    let icons:Resource[] = [
      $r('app.media.arrow_left_to_line'),
      $r('sys.symbol.house'),
      $r('sys.symbol.arrow_left'),
      $r('sys.symbol.arrow_clockwise'),
      $r('sys.media.ohos_ic_public_more')
    ];
    for (let i = 0; i < icons.length; i++) {
      let rs:Resource = icons[i];
      this.toolbarList.push( new ToolBarV2Item({
        content: new ToolBarV2ItemText({ text: '' } ),
        icon: new ToolBarV2ItemImage({
          src: rs
        })
      ,
        action: () => {
          this.click(i);

         // this.$clickIndex(i);

          if(i == 4){
             this.isShowPopup = !this.isShowPopup;
          }
        },
        // accessibilityText: '剪贴', //该项屏幕朗读播报文本为‘剪贴’
        // accessibilityDescription: '单指双击即可剪贴', //该项屏幕朗读播报描述为'单指双击即可剪贴'
        // accessibilityLevel: 'yes'  //该项可被无障碍屏幕朗读聚焦
      })

      )
    }
  }

  build() {
    Column() {
      Row() {
        Stack() {
          Column() {
            ToolBarV2({
              toolBarModifier: this.toolBarModifier,
              dividerModifier: this.dividerModifier,
              toolBarList: this.toolbarList,
            })
              .width('100%')
              .height('100%')
              //.height(56)
             // .bindMenu(this.isShowPopup, this.MyMenu,{placement:Placement.TopRight,})
              .bindPopup(this.isShowPopup, {
                builder: this.popupBuilder,
                placement:Placement.TopRight,
                radius: 5,
                onStateChange: (e) => {
                  this.isShowPopup = e.isVisible
                }
              })
          }
        }
        .width('100%')
        .height('100%')
        //.align(Alignment.Bottom)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    //.height(56)
    //.align(Alignment.Bottom)
  }

  private  onPopItemSelected(type:MPIType){
    this.click(type);

   // this.$clickIndex(type);

    this.isShowPopup =false;
  }

  @Builder
  popupBuilder() {
      MorePopup({accessSiteType:this.accessSiteType, click:(type:MPIType)=>{
          this.onPopItemSelected(type);
      }})
  }



  @Builder
  MyMenu() {
    Menu() {
      MenuItem({ content: '下载文件' })
        .width(103)
        .onClick(() => {
        })
      MenuItem({ content: '上传文件' })
        .width(103)
        .onClick(() => {
        })
    }
    .menuItemDivider({
      strokeWidth: new LengthMetrics(0.5),
      color: '#E6000000',
      startMargin: new LengthMetrics(0),
      endMargin: new LengthMetrics(0)
    })
  }


}




//
//
// import {
//   ToolBarOptions,
//   ToolBar} from '@kit.ArkUI';
// @Component
// export  struct WebToolBar {
//   @State  toolbarList: ToolBarOptions = new ToolBarOptions();
//   @Link event:number;
//
//   aboutToAppear() {
//     //后退到顶
//     this.toolbarList.push({
//       content: '',
//       icon: $r('app.media.arrow_left_to_line'),
//       action: () => {
//         this.event = 0;
//       },
//     })
//     //goto home
//     this.toolbarList.push({
//       content: '',
//       icon: $r('sys.symbol.house'),
//       action: () => {
//         this.event = 1;
//       },
//       //state: ItemState.DISABLE
//     })
//     //back
//     this.toolbarList.push({
//       content: '',
//       icon: $r('sys.symbol.arrow_left'),
//       action: () => {
//         this.event = 2;
//       },
//       //state: ItemState.ACTIVATE
//     })
//     //刷新
//     this.toolbarList.push({
//       content: '',
//       icon: $r('sys.symbol.arrow_clockwise'),
//       action: () => {
//         this.event = 3;
//       },
//
//     })
//     //more
//     this.toolbarList.push({
//       content: '',
//       icon: $r('sys.media.ohos_ic_public_more'),
//       action: () => {
//         this.event = 4;
//       },
//     })
//   }
//
//   build() {
//     Column() {
//       Row() {
//         Stack() {
//           Column() {
//             ToolBar({
//               toolBarList: this.toolbarList,
//             })
//           }
//         }
//         .width('100%')
//         .align(Alignment.Bottom)
//         //.height('100%')
//       }
//     }
//   }
//
// }