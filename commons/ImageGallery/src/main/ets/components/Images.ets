import { PhotoGesture } from '../model/GestureData';
import { MyDataSource } from '../model/MyDataSource';
import { IconData, StyleData } from '../interface/PicturePreviewInterface'
import { PictureCacheUtil } from '../utils/PictureCacheUtil';
import { PicturePreview } from '../PicturePreview';
import { Loading } from './Loading';
import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';
import { common } from '@kit.AbilityKit';
import { ImgDownloadCallBack } from '../interface/ImgDownloadCallBack';

@Component
export struct Images{
  @Link index: number;
  @Link imageValid: boolean;

  @State styleData: StyleData = PicturePreviewDataModel.getInstance().styleData;
  @Prop iconDatas: MyDataSource<IconData>;
  @State isDisableSwipe: boolean = false
  private init: boolean = false;
  public loading: ((iconData: IconData)=>void) | undefined;

  private controller: SwiperController = new SwiperController()

  click(index: number, iconData: IconData) {
    // 执行点击事件，如果返回true，则默认已经处理了点击事件，则不执行关闭动作
    let fn = PicturePreviewDataModel.getInstance().listener.onClick!;
    let is = fn(index, iconData);
    if (is) return;

    // 如果设置了点击关闭，则关闭页面
    if (PicturePreviewDataModel.getInstance().functionData.isClickClose) {
      PicturePreview.close();
    }
  }

  doubleClick(index: number, iconData: IconData): boolean {
    let fn = PicturePreviewDataModel.getInstance().listener.onDoubleTap!;
    let is = fn(index, iconData);
    if (is) {
      return true
    } else {
      return false
    }
  }

  build() {
    Swiper(this.controller){
      LazyForEach(this.iconDatas, (item: IconData)=>{
        ImageIte({
          item: item,
          imageValid:this.imageValid,
          isDisableSwipe: this.isDisableSwipe,
          maxScale: this.styleData.maxScale,
          isZoom: this.styleData.isZoom,
          loading: this.loading,
          click: ()=>{
            this.click(this.index, item)
          },
          doubleClick: ()=>{
            return this.doubleClick(this.index, item)
          }
        })
      })
    }.indicator(false)
    .disableSwipe(this.isDisableSwipe)
    .loop(false)
    .onSizeChange(() => {
      if (!this.init) {
        this.controller.changeIndex(this.index, false)
        this.init = true;
      }
    })
    .onChange((index)=>{
      let fn = PicturePreviewDataModel.getInstance().listener.onChange!
      fn(index, this.iconDatas.getData(index))
    })
    .onAnimationStart((index: number, targetIndex: number)=>{
      this.index = targetIndex;
      let fn = PicturePreviewDataModel.getInstance().listener.onAnimationStart!
      if (targetIndex != index) {
        fn(index, this.iconDatas.getData(index), targetIndex, this.iconDatas.getData(targetIndex))
      }
    })
    .onAnimationEnd((index: number)=>{
      let fn = PicturePreviewDataModel.getInstance().listener.onAnimationEnd!
      fn(index, this.iconDatas.getData(index))
    })
  }
}

@Component
struct ImageIte{
  @Prop item: IconData
  @Link imageValid: boolean;
  @Link isDisableSwipe: boolean;
  @Prop isZoom: boolean
  @Prop maxScale: number = 5;
  @State @Watch("setIsDisableSwipe") photoPinchGesture: PhotoGesture = new PhotoGesture(this.maxScale,this.getUIContext());
  @State private isError: boolean = false;
  @State private isLoading: boolean = true;
  @BuilderParam public loading: ((iconData: IconData)=>void) | undefined;
  @State downloadCallBack:ImgDownloadCallBack = new ImgDownloadCallBack();
  @State bgDownloading:boolean = false;

  // 单击事件
  click: () => void = ()=>{

  }

  // 双击
  doubleClick: () => boolean = ()=>{
    return false
  }

  // 图片地址
  @State path: ResourceStr = $r('app.media.photo_gallery_image_loading')
  private pictureCacheUtil: PictureCacheUtil = new PictureCacheUtil( this.getUIContext().getHostContext() as common.UIAbilityContext);//; getContext());
  aboutToAppear(): void {
    this.downloadCallBack.url = this.item.url;
    this.downloadCallBack.filePath = this.item.path;
    this.downloadCallBack.onStart = (url:string)=>{
      this.bgDownloading  = true;
      this.imageValid = false;
    };
    this.downloadCallBack.onFinished = (url:string,path:string,error:boolean)=>{
      if(error)
      {
        this.isError = error;
        this.imageValid=false;
      }else{
        ///file://com.redpig.chiphell/data/storage/el2/base/haps/default/files/MediaLibrary_Image/161804tpkkue1ef4tc1eth.jpg
        ///data/storage/el2/base/haps/default/files/MediaLibrary_Image/161806d99m1l0pmcfpimpa.jpg
        this.path = path;
        if(this.item.path === undefined || this.item.path.length == 0){
          this.item.path = path;
        }
        this.imageValid=true;
      }
      this.bgDownloading  = false;
    };
    this.getPath()
  }

  private getPath() {
   // this.path = $r('app.media.photo_gallery_image_loading')
    this.path = this.pictureCacheUtil.getPathOrUrl(this.item.path!, this.item.url! ,this.downloadCallBack);
    if( (this.path !== undefined) && ( this.path === this.item.url!)){
      this.bgDownloading = true;
    }
    else{
      if(this.item.path === undefined || this.item.path.length == 0){
        if( (this.path !== undefined ) && (this.path as string) && (this.path.length>0) && this.path.startsWith('file',0) )
        {
          this.item.path = this.path;
          this.imageValid=true;
        }else{
          this.imageValid=false;
        }
      }else {
        this.imageValid=true;
      }
      this.bgDownloading = false;
    }
  }

  setIsDisableSwipe(){
    this.isDisableSwipe = (this.photoPinchGesture.scale > 1.2)
  }

  @Styles _PanGestureGesture() {
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PinchGesture({ fingers: 2})
          .onActionUpdate((e) => {
            if (this.isZoom)
              this.photoPinchGesture.onPinchGestureActionUpdate(e)
          })
          .onActionEnd(()=>{
            if (this.isZoom)
              this.photoPinchGesture.onPinchGestureActionEnd()
          }),
        PanGesture()
          .onActionStart((e)=>{
            this.photoPinchGesture.onPanGestureActionStart()
          })
          .onActionUpdate((e)=>{
            if (this.photoPinchGesture.scale > 1) {
              this.photoPinchGesture.onPanGestureActionUpdate(e)
            }
          })
          .onActionEnd(()=>{
            if (this.photoPinchGesture.scale > 1) {
              this.photoPinchGesture.onPanGestureActionEnd()
            }
          }),
      )
    )
  }

  @Styles _Gesture() {
    .gesture(
      PinchGesture({ fingers: 2})
        .onActionUpdate((e) => {
          if (this.isZoom)
            this.photoPinchGesture.onPinchGestureActionUpdate(e)
        })
        .onActionEnd(()=>{
          if (this.isZoom)
            this.photoPinchGesture.onPinchGestureActionEnd()
        })
    )
  }

  @Builder MyImage() {
    if(this.bgDownloading){
      // Image(this.path)
      //   .objectFit(ImageFit.Contain)
      //   .sharedTransition("image")
      //   .draggable(false)
      //   .width("100%")
      //   .onComplete((event)=>{
      //     // 图片加载完成
      //     this.isLoading = false;
      //     this.photoPinchGesture.imageWidth = this.getUIContext().px2vp(event?.contentWidth!);
      //     this.photoPinchGesture.imageHeight = this.getUIContext().px2vp(event?.contentHeight!);
      //   })
      //
      //   .onError((error: ImageError)=>{
      //     this.isError = true;
      //     setTimeout(()=>{
      //       this.isLoading = true;
      //       this.pictureCacheUtil.deletePath(this.path as string);
      //       this.getPath();
      //     }, 100)
      //   })
      //   .scale({
      //     x: this.photoPinchGesture.scale,
      //     y: this.photoPinchGesture.scale,
      //   })
      //   .offset({
      //     x: this.photoPinchGesture.offsetX,
      //     y: this.photoPinchGesture.offsetY
      //   })
    }
    else{
      ///失败url： data/storage/el2/base/haps/default/files/MediaLibrary_Image/161806d99m1l0pmcfpimpa.jpg
      //成功：file://com.redpig.chiphell/data/storage/el2/base/haps/default/files/MediaLibrary_Image/161804tpkkue1ef4tc1eth.jpg
      Image(this.path)
        .objectFit(ImageFit.Contain)
        .sharedTransition("image")
        .draggable(false)
        .width("100%")
        .onComplete((event)=>{
          // 图片加载完成
          this.isLoading = false;
          this.photoPinchGesture.imageWidth = this.getUIContext().px2vp(event?.contentWidth!);
          this.photoPinchGesture.imageHeight = this.getUIContext().px2vp(event?.contentHeight!);
        })

        .onError((error: ImageError)=>{
          this.isError = true;
          setTimeout(()=>{
            this.isLoading = true;
            this.pictureCacheUtil.deletePath(this.path as string);
            this.getPath();
          }, 100)
        })
        .scale({
          x: this.photoPinchGesture.scale,
          y: this.photoPinchGesture.scale,
        })
        .offset({
          x: this.photoPinchGesture.offsetX,
          y: this.photoPinchGesture.offsetY
        })
    }
  }

  build() {
    Stack(){
      if (!this.isError) {
        Column(){
          this.MyImage()
        }.width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Center)
        ._Gesture()

        if (this.photoPinchGesture.isPanImage) {
          Column(){
            this.MyImage()
          }.width("100%")
          .height("100%")
          .justifyContent(FlexAlign.Center)
          ._PanGestureGesture()
        }

        // loading
        if (this.isLoading) {
          // 自定义loading是否存在
          if (this.loading) {
            this.loading(this.item)
          } else {
            Loading()
          }
        }
      } else {
        Column({space: 10}){
          Image($r('app.media.ic_gallery_list_damage2'))
            .interpolation(ImageInterpolation.High)
            .width(40)
            .height(40)

          Text("加载失败 点击重试")
            .fontColor("#fff")
        }.width("100%")
        .height("100%")
        .justifyContent(FlexAlign.Center)
        .onTouch((e)=>{
          e.stopPropagation()
        })
        .onClick(()=>{
          this.getPath()
          this.isError = false;
          this.isLoading = true
        })
      }
    }.onTouch((event: TouchEvent)=>{
      this.photoPinchGesture.clickOrDoubleClick(event, (type: number) => {
        let is = false;
        switch (type) {
          case 0:
            this.click()
            break;
          case 1:
            is = this.doubleClick()
            break;
        }
        return is;
      }, this.isZoom);
    })
  }
}