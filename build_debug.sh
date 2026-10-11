#!/bin/bash

# 环境变量
PROJECT_DIR="/Users/zorro/Documents/Dev/huawei/Zorro/chiphell_hm"
OUTPUT_DIR="${PROJECT_DIR}/output"
BUILD_TYPE=${1:-debug}

echo "开始构建鸿蒙应用..."

# 清理旧构建
rm -rf ${OUTPUT_DIR}

# 安装依赖
cd ${PROJECT_DIR}
npm install

# 执行构建
if [ "$BUILD_TYPE" = "release" ]; then
    echo "构建Release版本..."
    npm run build:release
else
    echo "构建Debug版本..."
    npm run build
fi

# 检查构建结果
if [ -f "${PROJECT_DIR}/entry/build/default/outputs/default/entry-default-unsigned.hap" ]; then
    echo "构建成功！"
    # 复制到输出目录
    mkdir -p ${OUTPUT_DIR}
    cp ${PROJECT_DIR}/entry/build/default/outputs/default/*.hap ${OUTPUT_DIR}/

    # 列出生成的文件
    echo "生成文件："
    ls -la ${OUTPUT_DIR}/
else
    echo "构建失败！"
    exit 1
fi