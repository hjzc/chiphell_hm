
@ObservedV2
export class WebRecord {
  title:string|null = null;
  url :string='';
  createDate:number = 0;
  updateDate:number = 0;
  access = 0;
  accessDate:number = 0;
  @Trace favor:number = 0;
  favorDate:number = 0;
  deleted:number = 0;
}