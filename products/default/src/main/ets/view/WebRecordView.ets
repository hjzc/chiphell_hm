import { WebRecordDataSource } from '../model/WebRecordDataSource';
import { common } from '@kit.AbilityKit';
import { WebRecord } from '../model/WebRecord';
import { DialogHelper } from 'dialog';
import { AppUtil } from '../utils/AppUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { WebRecordDbModel } from '../model/WebRecordDbModel';
import { BreakpointType, logger } from 'utils';
import { AppStorageV2 } from '@kit.ArkUI';
import { ZjStorage } from '../Storage/ZjStorage';
import { WantUtil } from '../utils/WantUtil';

@ComponentV2
export  struct WebRecordView{
  @Param storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  @Require @Param db :WebRecordDbModel;
  @Require @Param favorData: WebRecordDataSource;
  @Require @Param  historyData: WebRecordDataSource;
  @Param isFavor:boolean = true;
  @Event shouldLoadingMore:()=> void = ()=>{

  };

  @Local isMoreShowed:boolean = false;
  @Local isScrollToEnd:boolean = false;

  getAbilityContext():common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  doTips(flag:boolean):void{
    ToastUtil.showToast(this.getUIContext(),$r(  flag? 'app.string.do_success':'app.string.do_failed' ));
  }

  data():WebRecordDataSource{
    return this.isFavor? this.favorData:this.historyData;
  }

  @Builder
  headImage(item:WebRecord,index:number) {
    if(AppUtil.is2N1Device()){
      Image($r( item.favor!=0? 'app.media.star_selected':'app.media.star' ))
        .width(40)
        .height(40)
        .padding({
          top: 8,
          left: 8,
          bottom: 8,
          right: 8
        })
        .onClick((event)=>{
          this.rowHeaderImageClickHandler(item,index);
        })
    }else{
      Image($r( item.favor!=0? 'app.media.star_selected':'app.media.star' ))
        .width(20)
        .height(20)
        .onClick((event)=>{
          this.rowHeaderImageClickHandler(item,index);
        })
    }
  }

  @Builder
  endImage(item:WebRecord,index:number) {
    if(AppUtil.is2N1Device()){
      Image($r('app.media.filter_del'))
        .width(40)
        .height(40)
        .padding({
          top: 8,
          left: 8,
          bottom: 8,
          right: 8
        })
        .onClick((event)=>{
          this.rowTrailingImageClickHandler(item,index);
        })
    }else{
      Image($r('app.media.filter_del'))
        .width(20)
        .height(20)
        .padding({
          right: 0
        })
        .onClick((event)=>{
          this.rowTrailingImageClickHandler(item,index);
        })
    }
  }

  build() {
   // const isPC = AppUtil.isPCDevice();
    Column(){
      List() {
        LazyForEach(this.isFavor?this.favorData: this.historyData, (item: WebRecord, idx:number) => {
          ListItem() {
            Row() {
              Row(){
                this.headImage(item,idx)
                Blank()
                  .width(12)
                Column(){
                  Text(item.title)
                    .titleFancy()
                    // .textAlign(TextAlign.Start)
                    // .fontColor($r('sys.color.font_primary'))
                    // .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
                    // .maxLines(1)
                    // .padding({left:0,bottom:8})
                    //.width('100%')
                  Text(item.url)
                    .urlFancy()
                    // .textAlign(TextAlign.Start)
                    // .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
                    // .fontColor($r('sys.color.font_tertiary'))
                    // //.minFontSize(6)
                    // .minFontScale(0.3)
                    // .maxLines(1)
                    // .padding({left:0})
                     //.width('100%')
                }
                .width('84%')
                .justifyContent(FlexAlign.SpaceEvenly)

                .onClick(
                  (event)=>{
                    this.rowContentCopyOptions(item);
                  }
                )
              }
              .justifyContent(FlexAlign.SpaceEvenly)
              this.endImage(item,idx)
              // Image($r('app.media.filter_del'))
              //   .width(20)
              //   .height(20)
              //   .padding({right:0})
              //   .onClick((event)=>{
              //     this.rowTrailingImageClickHandler(item,idx);
              //   })
            }
            .height(66)
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ left: 12, right: 12 })
          }
          .width('100%')
          .height(66)
          .border({ width: { bottom: 1 }, color: $r('sys.color.comp_divider') })

        }, (item: WebRecord, index: number) => `${item}-${index}` )
        //行移动
        // .onMove((from: number, to: number) => {
        //   this.historyData.moveDataWithoutNotify(from, to);
        // })

        ListItem() {
          if (this.isMoreShowed ) {
            this.MoreLayout()
          } else {
            this.NoMoreLayout()
          }
        }
      }
      .cachedCount(5)
      .width('100%')
      .height('100%')
      //.margin({ left: '3.3%', right: '3.3%' })
      //设置List组件在sm、md、lg断点下List组件分别呈1列、1列、2列显示。依然可以使用List的lanes属性结合断点来实现效果。
      .lanes(new BreakpointType<number>({ sm:1, md: 1, lg: 2, xl: 2 }).getValue(this.storage.currentBreakpoint))
      .edgeEffect(EdgeEffect.None)
      // .divider({
      //   color: $r('app.color.dividerColor'),
      //   strokeWidth: Const.NewsListConstant_LIST_DIVIDER_STROKE_WIDTH,
      //   endMargin: Const.NewsListConstant_LIST_MARGIN_RIGHT
      // })
      .onScrollIndex((start: number, end: number) => {
        // this.scrollStartIndex = start;
        // this.scrollEndIndex = end;
        logger.debug('onScrollIndex start:',(''+start), (' end:'+end) );
        if (end == this.data().totalCount()) {
          if (this.data().hasMore()) {
            this.isMoreShowed = true;
          }else{
            this.isMoreShowed = false;
          }
          this.isScrollToEnd= true;
        }else{
          this.isScrollToEnd= false;
        }
      })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r('sys.color.background_primary'))
    .onTouch((event: TouchEvent | undefined) => {
      if (event) {
        if(event.type==  TouchType.Up){
          if (this.isScrollToEnd) {

            if (this.data().hasMore()) {
              this.isMoreShowed = true;
            }else{
              this.isMoreShowed = false;
            }

            if(this.isMoreShowed){
              if (this.data().isMoreLoading === false) {
                //开始执行更多
                logger.debug('可以执行更多' );
                if(this.shouldLoadingMore!==undefined){
                  logger.debug('开始执行更多中。。。。。' );
                  this.shouldLoadingMore();
                }
              }else{
                logger.debug('执行更多中。。。。。' );
              }
            }
          }

        }
      }
    })
  }

  private  rowContentCopyOptions(item: WebRecord):void{
    DialogHelper.showBottomSheetDialog({
      sheets: [$r('app.string.copy_title'), $r('app.string.copy_link'),$r('app.string.sheet_record_open'),$r('app.string.pop_menu_browse'),],
      onAction: (index) => {

        if (index <2 ) {
          let content = (index==0)?item.title:item.url;
          AppUtil.copyTextToPasteboard(content??'',(success:boolean)=>{
            let r =  success==true?$r('app.string.copy_success',2):$r('app.string.copy_failed',2);
            try {
              let testStr = (this.getUIContext().getHostContext() as common.UIAbilityContext).resourceManager.getStringSync(r.id);
              ToastUtil.showToast(this.getUIContext()!, testStr);
            } catch (error) {
            }
          });
        }else if(index == 2){
          //打开
          this.storage.openHistoryUrl = item.url;

        }else if(index == 3){
          //其他应用打开
          WantUtil.toWebBrowser(item.url,true);
        }



      }
    })
  }

  private  rowHeaderImageClickHandler(item:WebRecord, idx:number):void{
    if(this.isFavor){
      //收藏页面
      if(item.deleted ==0 ){
        //取消收藏标记
        let upitem = this.db.copyItem(item);
        upitem.favor = 0;
        upitem.favorDate = new Date().getTime();
        this.db.updateRecord(this.getAbilityContext(), upitem).then((val) => {
          if (val) {
            item.updateDate = upitem.updateDate;
            item.favorDate = upitem.favorDate;
            item.favor = upitem.favor;
            this.doTips(true);
            //在收藏列表中删除
            this.favorData.removeDataOfIndex(idx);
            this.favorData.dbTotal -= 1;
            //在历史列表中找到对应项目，同步favor 和favorDate
            this.historyData.traverseSetFavorData(item);
          } else {
            this.doTips(false);
          }
        });

      }else{
        //从数据库中删除
        this.db.deleteRecord(this.getAbilityContext(),item).then(
          (val)=>{
            if(val){
              //成功,从列表数据源中删除
              this.favorData.removeDataOfIndex(idx);
              this.favorData.dbTotal -= 1;
              //历史记录列表无此数据，不处理
              this.doTips(true);
            }else{
              //失败
              this.doTips(false);
            }
          }
        );
      }

    }
    else {
      //历史页面
      if (item.favor == 0) {
        //收藏，后插入到收藏列表最前面
        let upitem = this.db.copyItem(item);
        upitem.favor = 1;
        upitem.favorDate = new Date().getTime();
        this.db.updateRecord(this.getAbilityContext(), upitem).then((val) => {
          if (val) {
            item.updateDate = upitem.updateDate;
            item.favorDate = upitem.favorDate;
            item.favor = upitem.favor;
            //追加到收藏列表最前端
            this.favorData.unshiftData(item);
            this.favorData.dbTotal +=1;
            this.doTips(true);
          } else {
            this.doTips(false);
          }
        });

      } else {
        if (item.deleted != 0) {
          //不应该出现这个情况， 设置了删除标记，将从数据库中删除
        } else {
          //取消收藏标记
          let upitem = this.db.copyItem(item);
          upitem.favor = 0;
          upitem.favorDate = new Date().getTime();
          this.db.updateRecord(this.getAbilityContext(), upitem).then((val) => {
            if (val) {
              item.updateDate = upitem.updateDate;
              item.favorDate = upitem.favorDate;
              item.favor = upitem.favor;
              this.doTips(true);
              //在收藏列表中找到对应项目，也取消收藏标记,从数据源中删除url相同item
              this.favorData.traverseRemoveData(item);
              this.favorData.dbTotal -= 1;
            } else {
              this.doTips(false);
            }
          });
        }
      }
    }
  }

  private  rowTrailingImageClickHandler(item:WebRecord, idx:number):void{

    if(this.isFavor){
      //收藏页面
      //从数据库中删除
      this.db.deleteRecord(this.getAbilityContext(),item).then(
        (val)=>{
          if(val){
            //成功,从列表数据源中删除
            this.favorData.removeDataOfIndex(idx);
            this.favorData.dbTotal -=1;
            //从历史记录列表数据源中删除
            this.historyData.traverseRemoveData(item);
            this.historyData.dbTotal -=1;
            this.doTips(true);
          }else{
            //失败
            this.doTips(false);
          }
        }
      );
    }
    else{
      //历史页面
      if (item.favor == 0 ) {
        //从数据库中删除
        this.db.deleteRecord(this.getAbilityContext(),item).then(
          (val)=>{
            if(val){
              //成功
              this.historyData.removeDataOfIndex(idx);
              this.historyData.dbTotal -=1;
              this.doTips(true);
            }else{
              //失败
              this.doTips(false);
            }
          }
        );
      }else{
        //set deleted flag
        let del:number = item.deleted;
        item.deleted  = 1;
        this.db.updateRecord(this.getAbilityContext(),item).then(
          (val)=>{
            if(val){
              //成功
              this.historyData.removeDataOfIndex(idx);
              this.historyData.dbTotal -=1;
              this.doTips(true);
            }else{
              //失败
              item.deleted = del;
              this.doTips(false);
            }
          }
        );
      }
    }
  }

  @Builder
  NoMoreLayout() {
    Row() {
      Text($r('app.string.no_more_data'))
        .margin({ left:8 })
        .fontSize('16fp')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .height(70)
  }

  @Builder
  MoreLayout() {
    Row() {
      Text($r( this.data().isMoreLoading? 'app.string.data_loading': 'app.string.more_data' ))
        .margin({ left:8 })
        .fontSize('16fp')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .height(70)
  }
}

// @Extend(Text)可以支持Text的私有属性minFontSize
@Extend(Text)
function titleFancy() {
  .textAlign(TextAlign.Start)
  .fontColor($r('sys.color.font_primary'))
  .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
  .maxLines(1)
  .padding({left:0,bottom:8})
  .width('100%')
}

@Extend(Text)
function urlFancy() {
  .textAlign(TextAlign.Start)
  .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
  .fontColor($r('sys.color.font_tertiary'))
  //.minFontSize(6)
  .minFontScale(0.3)
  .maxLines(1)
  .padding({left:0})
  .width('100%')
}


