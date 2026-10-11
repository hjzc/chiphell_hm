# chiphell_hm

鸿蒙6.0

2. 依赖下载失败
# 配置ohpm镜像源
ohpm config set registry https://repo.harmonyos.com/ohpm/

3. HAP文件过大
## 1. 压缩资源图片
## 2. 启用混淆和压缩
## 在build-profile.json5中添加：
'''code
"optimize": {
"proguard": true,
"removeUnusedResource": true
}
'''

四、HAP和APP Pack
1. HAP文件结构
   text

entry-default-signed.hap
├── ets/
├── resources/
├── module.json
├── pack.info
└── signature

2. 生成APP Pack（应用商店发布）
   bash

# 1. 准备多个HAP（如手机、平板、车机版）
# 2. 创建app_pack目录结构
app_pack/
├── 手机HAP文件
├── 平板HAP文件
├── pack.info
└── 签名文件

# 3. 使用命令行工具打包
java -jar app_packing_tool.jar --mode multi-hap \
--json-path config.json --profile-path signature.p7b \
--in-path ./app_pack --out-path ./output/apppack.app


## 已知问题
图片下载被拦截，可能https证书问题


## 使用协议
本项目仅供个人学习与研究用途，下载内容仅限于个人非商业使用，严禁用于任何形式的商业目的、公开传播或分发。
本软件仅基于用户账号的合法访问权限操作，不会绕过任何付费墙或平台知识产权保护措施。请勿将本软件用于批量抓取或任何违反目标平台服务条款的行为。

免责声明：用户需完全自行承担使用本项目可能带来的所有风险（包括但不限于账号封禁、版权纠纷等）。项目开发者不对任何人因使用或无法使用本软件所引发的任何直接或间接法律纠纷、损害承担责任。

继续使用即表示您已充分理解并同意遵守上述全部条款。


## 许可证

[MIT](./LICENSE)