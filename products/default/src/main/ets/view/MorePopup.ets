import { MorePopItemData, MPIType } from "../model/ToolBarMorePopModel";
import { AccessSiteType } from "../model/WebSite";
import { env } from "../Storage/ZjEnv";
import { AppUtil } from "../utils/AppUtil";


@ComponentV2
export  struct MorePopup {
  @Param accessSiteType :AccessSiteType = AccessSiteType.pc;
  @Event click: (index:MPIType) => void;
  private items:MorePopItemData[] = [];

  aboutToAppear(): void {
  //  let i:number = 0;
    if(!env.login){
      this.items.push(
        {
          type : MPIType.LOGIN,
          title:$r('app.string.pop_menu_login'),
          icon:$r('app.media.login'),
        }
      );
    }
    this.items.push(
      {
        type : MPIType.BROWSER,
        title:$r('app.string.pop_menu_browse'),
        icon:$r('app.media.safari'),
      }
    );
    this.items.push(
      {
        type : MPIType.COPY,
        title:$r('app.string.pop_menu_copy'),
        icon:$r('app.media.copy'),
      }
    );
    this.items.push(
      {
        type : MPIType.FORUM,
        title: $r('app.string.pop_menu_forum'),
        icon:$r('app.media.forum'),
      }
    );
    this.items.push(
      {
        type : MPIType.GALLERY,
        title: $r('app.string.pop_menu_gallery'),
        icon:$r('app.media.gallery'),
      }
    );
    this.items.push(
      {
        type : MPIType.HISTORY,
        title: $r('app.string.web_record'),
        icon:$r('app.media.history'),
      }
    );
    this.items.push(
      {
        type : MPIType.FILTER,
        title:$r('app.string.web_replay_user_filter'),
        icon:$r('app.media.customer_filter'),
      }
    );

    if ( AppUtil.is2N1Device()==false ) {
      this.items.push(
        {
          type : MPIType.UA,
          title: this.accessSiteType==AccessSiteType.pc?  $r('app.string.web_ua_mobile') : $r('app.string.web_ua_pc'),
          icon: this.accessSiteType==AccessSiteType.pc? $r('app.media.user_agent_mobile') :$r('app.media.user_agent_pc'),
        }
      );
    }


    this.items.push(
      {
        type : MPIType.SETTING,
        title:$r('app.string.app_settings'),
        icon:$r('app.media.settings'),
      }
    );
  }

  build() {
    Column() {
      ForEach(this.items, (item: MorePopItemData) => {
        Row() {
          Blank()
            .width(16)
          Image(item.icon)
            .width(20)
            .height(20)
          Blank()
          Text(item.title)
            .textAlign(TextAlign.Center)
            .fontSize($r('sys.float.ohos_id_popup_text_font_size'))
            //.padding({ right:-10 })
            //.margin({ right: 16 })
          Blank()
            .width(16)
        }
        .width(100)
        .height(40)
        //.padding({ left:8,right:8 })
        .justifyContent(FlexAlign.SpaceBetween)
        .onClick(
          (event)=>{
            this.click(item.type);
          }
        )
        .border({ width: { bottom:item.type != MPIType.SETTING? 1:0 }, color: $r('sys.color.comp_divider') })



      })

    }
  }

}