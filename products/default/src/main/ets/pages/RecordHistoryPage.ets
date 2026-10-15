
import { env } from "../Storage/ZjEnv";
import { AppStorageV2, SwipeRefresher } from "@kit.ArkUI";
import { WebRecordDataSource } from "../model/WebRecordDataSource";
import { getDBManager } from "../common/DBManager";
import { common } from "@kit.AbilityKit";
import { ZjStorage } from "../Storage/ZjStorage";
import { WebRecordDbModel } from "../model/WebRecordDbModel";
import { WebRecordView } from "../view/WebRecordView";

@ComponentV2

export struct RecordHistoryPage{
  @Consumer('webPageStack') webPageStack: NavPathStack = new NavPathStack();
  @Local storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  @Local statusBarHeight: number = env.statusBarHeight;
  private db :WebRecordDbModel = new WebRecordDbModel(getDBManager().store!);
  private controller: TabsController = new TabsController()
  @Local currentIndex:number = 0;
  @Local favorData: WebRecordDataSource = new WebRecordDataSource();
  @Local historyData: WebRecordDataSource = new WebRecordDataSource();

  aboutToAppear(): void {
    this.loadFavorData(false,()=>{
        this.loadFavorCount(()=>{
          this.loadHistoryCount();
        });
    });
  }

  getAbilityContext():common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  loadFavorData(more:boolean, end?:()=>void ):void{
    if(more){
      if(this.favorData.isMoreLoading){
        return;
      }
      this.favorData.isMoreLoading = true;
    }
    else{
      if(this.favorData.isLoading){
        return;
      }
      this.favorData.isLoading = true;
    }
    this.db
      .readRecordList(this.getAbilityContext(), undefined,true,this.favorData.offset() ,this.favorData.pageSize)
      .then(recordArray => {
        if(recordArray.length > 0){
          if(this.favorData.pageSize == recordArray.length) {
            //more
            //this.favorData.more = true;
          }else {
            //no more
            //this.favorData.more =false;
          }
        }else{
          //this.favorData.more =false;
        }
        this.favorData.pushDataList(recordArray);
        if(more){
          this.favorData.isMoreLoading = false;
        }
        else{
          this.favorData.isLoading = false;
        }
        if(end!==undefined){
          end();
        }
      });
  }

  loadFavorCount(end?:()=>void ):void{
    this.db.queryRecordCount(this.getAbilityContext(),undefined,true).then((count)=> {
      if (count>=0) {
        this.favorData.dbTotal = count;
      }
      if(end!==undefined){
        end();
      }
    });
  }

  loadHistoryData(more:boolean):void{
    if(more){
      if(this.historyData.isMoreLoading){
        return;
      }
      this.historyData.isMoreLoading = true;
    }
    else{
      if(this.historyData.isLoading){
        return;
      }
      this.historyData.isLoading = true;
    }
    this.db
      .readRecordList(this.getAbilityContext(), undefined,undefined,this.historyData.offset() ,this.historyData.pageSize)
      .then(recordArray => {
        if(recordArray.length > 0){
          if(this.historyData.pageSize == recordArray.length) {
              //more
            //this.historyData.more = true;
          }else {
             //no more
            //this.historyData.more =false;
          }
        }else{
          //this.historyData.more =false;
        }
        this.historyData.pushDataList(recordArray);
        if(more){
          this.historyData.isMoreLoading = false;
        }
        else{
          this.historyData.isLoading = false;
        }
      });
  }

  loadHistoryCount():void{
    this.db.queryRecordCount(this.getAbilityContext(),undefined,undefined).then((count)=> {
      if (count>=0) {
        this.historyData.dbTotal = count;
      }
    });
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部标签栏
        Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
          // 页签1
          TabContent() {
            this.FavoritesPage()
            if (this.favorData.isLoading){
              this.loadingView()
            }
          }.tabBar($r('app.string.web_record_tab1'))
          // 页签2
          TabContent() {
            this.historyPage()
            if (this.historyData.isLoading){
              this.loadingView()
            }
          }.tabBar($r('app.string.web_record_tab2'))
        }
        .barMode(BarMode.Fixed) // 固定宽度模式
        .barWidth('100%') // 宽度占满
        .barHeight(40) // 高度设置
        //.animationDuration(400)
        .onChange((index: number) => {
          this.currentIndex = index;
          if (this.currentIndex==1 ) {
            if (this.historyData.totalCount()==0) {
              if(this.historyData.isLoading==false){
                this.loadHistoryData(false);
              }
            }
          }
        })
        .backgroundColor($r('sys.color.background_secondary'))
        .border({ width: {  bottom: 1 }, color: $r('sys.color.comp_divider') })
      }
    }
    // .menus( this.AddMenu() )
    .title($r('app.string.page_record_title'))
    .backgroundColor($r('sys.color.background_primary'))
    //.border({ width: {  bottom: 1 }, color: $r('sys.color.comp_divider') })
    .margin({ top: this.getUIContext() ? this.getUIContext().px2vp(this.statusBarHeight) : 0, bottom: 0 })
    .onBackPressed(() => {
      return false;
    });

  }

  @Builder
  loadingView(){
    Column(){
     Column(){
       Column(){
         SwipeRefresher({isLoading: true}) //content: "加载中....."
       }
       .width("100")
       .height("100")
       .borderRadius(15)
       .justifyContent(FlexAlign.Center)
       .backgroundColor($r('sys.color.background_fourth'))
     }
     //.padding({top:0})
     .width("100%")
     .height("76%")
     .justifyContent(FlexAlign.Center)
     // .margin({ top:0  }) // 顶部避让

    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  FavoritesPage(){
    WebRecordView({
      db:this.db,
      historyData:this.historyData,
      favorData:this.favorData,
      storage:this.storage,
      isFavor:true,
      shouldLoadingMore:()=>{
        this.loadFavorData(true);
      }
    })
  }



  @Builder
  historyPage(){
    WebRecordView({
      db:this.db,
      historyData:this.historyData,
      favorData:this.favorData,
      storage:this.storage,
      isFavor:false,
      shouldLoadingMore:()=>{
        this.loadHistoryData(true);
      }
    })














    // Column(){
    //   List() {
    //     LazyForEach(this.historyData, (item: WebRecord, idx:number) => {
    //       ListItem() {
    //         Row() {
    //           Row(){
    //             Image($r( item.favor!=0? 'app.media.star_selected':'app.media.star' ))
    //               .width(20)
    //               .height(20)
    //               .onClick((event)=>{
    //                 if (item.favor==0) {
    //                   //收藏，后插入到收藏列表最前面
    //                 }else{
    //                   if (item.deleted !=0) {
    //                     //设置了删除标记，将从数据库中删除
    //
    //
    //                   }else{
    //                     //取消收藏标记
    //                     item.favor = 0;
    //                     let fd = item.favorDate;
    //                     item.favorDate =new Date() .getTime();
    //                     this.db.updateRecord(this.getAbilityContext(),item).then((val)=>{
    //                       if (val) {
    //                         this.doTips(true);
    //                         //在收藏列表中找到对应项目，也取消收藏标记,从数据源中删除
    //                         this.favorData.traverseRemoveData(item);
    //                       }else{
    //                         item.favorDate =fd;
    //                         item.favor = 1;
    //                         this.doTips(true);
    //                       }
    //                     });
    //
    //                   }
    //                 }
    //               })
    //             Blank()
    //               .width(12)
    //             Column(){
    //               Text(item.title)
    //                 .textAlign(TextAlign.Start)
    //                 .fontColor($r('sys.color.font_primary'))
    //                 .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
    //                 .maxLines(1)
    //                 .padding({left:0,bottom:8})
    //                 .width('100%')
    //               Text(item.url)
    //                 .textAlign(TextAlign.Start)
    //                 .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
    //                 .fontColor($r('sys.color.font_tertiary'))
    //                 .minFontScale(0.3)
    //                 .maxLines(1)
    //                 .padding({left:0})
    //                 .width('100%')
    //             }
    //             .width('84%')
    //             .justifyContent(FlexAlign.SpaceEvenly)
    //             .onClick(
    //               (event)=>{
    //                 this.copyOptions(item);
    //               }
    //             )
    //           }
    //           .justifyContent(FlexAlign.SpaceEvenly)
    //
    //           Image($r('app.media.filter_del'))
    //             .width(20)
    //             .height(20)
    //             .padding({right:0})
    //             .onClick((event)=>{
    //               if (item.favor ==0 ) {
    //                 //delete
    //                 this.db.deleteRecord(this.getAbilityContext(),item).then(
    //                   (val)=>{
    //                     if(val){
    //                       //成功
    //                       this.historyData.removeDataOfIndex(idx);
    //                       this.doTips(true);
    //                     }else{
    //                       //失败
    //                       this.doTips(false);
    //                     }
    //                   }
    //                 );
    //               }else{
    //                 //set delete
    //                 let del:number = item.deleted;
    //                 item.deleted  = 1;
    //                 this.db.updateRecord(this.getAbilityContext(),item).then(
    //                   (val)=>{
    //                     if(val){
    //                       //成功
    //                       this.historyData.removeDataOfIndex(idx);
    //                       this.doTips(true);
    //                     }else{
    //                       //失败
    //                       item.deleted = del;
    //                       item.deleted  = 0;
    //                       this.doTips(false);
    //                     }
    //                   }
    //                 )
    //               }
    //
    //             })
    //         }
    //         .height(66)
    //         .justifyContent(FlexAlign.SpaceBetween)
    //         .margin({ left: 12, right: 12 })
    //       }
    //       .width('100%')
    //       .height(66)
    //       .border({ width: { bottom: 1 }, color: $r('sys.color.comp_divider') })
    //
    //     }, (item: WebRecord, index: number) => `${item}-${index}` )
    //       //行移动
    //       // .onMove((from: number, to: number) => {
    //       //   this.historyData.moveDataWithoutNotify(from, to);
    //       // })
    //
    //   }
    //   .cachedCount(5)
    //   .width('100%')
    //   //设置List组件在sm、md、lg断点下List组件分别呈1列、1列、2列显示。依然可以使用List的lanes属性结合断点来实现效果。
    //   .lanes(new BreakpointType<number>({ sm:1, md: 1, lg: 2, xl: 2 }).getValue(this.storage.currentBreakpoint))
    // }
    // .width("100%")
    // .height("100%")
    // .justifyContent(FlexAlign.Start)
    // .backgroundColor($r('sys.color.background_primary'))
  }



  // copyOptions(item: WebRecord):void{
  //   DialogHelper.showBottomSheetDialog({
  //     sheets: [$r('app.string.copy_title'), $r('app.string.copy_link')],
  //     onAction: (index) => {
  //       let content = (index==0)?item.title:item.url;
  //       AppUtil.copyTextToPasteboard(content??'',(success:boolean)=>{
  //         let r =  success==true?$r('app.string.copy_success',2):$r('app.string.copy_failed',2);
  //         try {
  //           let testStr = (this.getUIContext().getHostContext() as common.UIAbilityContext).resourceManager.getStringSync(r.id);
  //           ToastUtil.showToast(this.getUIContext()!, testStr);
  //         } catch (error) {
  //         }
  //       });
  //     }
  //   })
  // }
  //
  // doTips(flag:boolean):void{
  //   ToastUtil.showToast(this.getUIContext(),$r(  flag? 'app.string.do_success':'app.string.do_failed' ));
  // }

}

@Styles
function rowStyle() {
  .width('100%')
  .height(56)
  .backgroundColor($r('sys.color.background_tertiary'))
  .margin({ bottom: 12 })
  .padding({ left: 12, right: 12 })
  .borderRadius(12)
}