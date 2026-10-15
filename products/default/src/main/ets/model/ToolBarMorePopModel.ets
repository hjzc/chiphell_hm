

export  enum MPIType{
  LOGIN=10,
  COPY=11,
  FORUM=12,
  GALLERY=13,
  HISTORY=14,
  FILTER=15,
  SETTING=16,
  BROWSER=17,
  UA=18,
  NONE=99,
}

export  interface  MorePopItemData{
  type:MPIType;
  title:string|Resource;
  icon:Resource;
}

@ObservedV2
export  class ToolBarMorePopModel{
  @Trace index:number  = -1;
  @Trace type:MPIType  = MPIType.NONE;
}
