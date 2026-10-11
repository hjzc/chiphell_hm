
import { SpinKit } from 'spinkit';
import { LoadingOptions } from '../model/LoadingOptions';
import { Helper } from '../utils/Helper';


@Component
export struct LoadingView {
  @Prop options: LoadingOptions;
  @State content: string = '';

  aboutToAppear(): void {
    if (this.options.content) {
      this.content = Helper.getResourceStr(this.options.content) ?? "";
    }
  }

  build() {
    Column() {
      SpinKit({
        spinType: this.options.loadType,
        spinSize: this.options.loadSize,
        spinColor: this.options.loadColor
      })
      Text(this.options.content)
        .textAlign(TextAlign.Center)
        .margin({ top: this.options.marginTop })
        .fontSize(this.options.fontSize)
        .fontColor(this.options.fontColor)
        .visibility(this.content.length > 0 ? Visibility.Visible : Visibility.None)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin(5)
    .padding(this.options.padding)
    .backgroundColor(this.options.backgroundColor)
    .borderRadius(this.options.borderRadius)
    .shadow(this.options.shadow)
    .constraintSize({
      minWidth: (this.content.length > 0 ? 116 : 96),
      minHeight: (this.content.length > 0 ? 116 : 96)
    })
  }

}