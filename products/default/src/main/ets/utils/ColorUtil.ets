

export  class ColorUtils {

  // Image($r('app.media.icon'))
  // .colorFilter(ColorFilterUtils.hexToColorMatrix('#4f0f48db'))
  static hexToColorMatrix(hex: string): number[] {
    // 格式校验（支持#AARRGGBB或RRGGBB）
    if (!/^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hex)) {
      throw new Error("Invalid hex color format");
    }
    let hexClean = hex.replace('#', '');
    if (hexClean.length === 6) hexClean = 'FF' + hexClean; // 补全透明度
    // 解析通道并归一化(0-1)
    const a = parseInt(hexClean.substr(0, 2), 16) / 255;
    const r = parseInt(hexClean.substr(2, 2), 16) / 255;
    const g = parseInt(hexClean.substr(4, 2), 16) / 255;
    const b = parseInt(hexClean.substr(6, 2), 16) / 255;
    // 构建矩阵（忽略原图颜色，直接填充目标色）
    return [
      0, 0, 0, 0, r, // 红色通道
      0, 0, 0, 0, g, // 绿色通道
      0, 0, 0, 0, b, // 蓝色通道
      0, 0, 0, a, 0  // 透明度通道
    ];
  }
}