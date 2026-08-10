#!/usr/bin/env bash
# 把 server/ 目录下的 go-music-api 后端交叉编译成 android/arm64 二进制，
# 伪装成 libgma.so 放进 jniLibs，供 App 启动时用 Process.start 拉起。
#
# 注意：CI(.github/workflows/build-apk.yml) 打包时会自己重新编译一份最新的，
# 不依赖这里生成/提交进仓库的文件。这个脚本是给本地不想等 CI、或者想在没
# 网的环境里离线验证 server/ 改动能不能编过用的，跑完记得把生成的
# libgma.so 一并 commit 一下，保持仓库里那份不要太旧。
#
# 用法: ./scripts/build_backend.sh
# 前提: 本机装了 Go 1.25+ (或者按 server/go.mod 里声明的最低版本)，
#       且能正常访问 proxy.golang.org / GitHub (普通开发机默认就行，
#       不需要像沙盒环境那样搞一堆 replace 指令绕网络限制)。
set -euo pipefail

cd "$(dirname "$0")/../server"

OUT_DIR="../android/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$OUT_DIR"

echo "==> go build (CGO_ENABLED=0 GOOS=android GOARCH=arm64)"
CGO_ENABLED=0 GOOS=android GOARCH=arm64 \
  go build -trimpath -ldflags="-s -w" -o "$OUT_DIR/libgma.so" .

ls -la "$OUT_DIR/libgma.so"
echo "==> 完成。libgma.so 已更新，可以直接 flutter build apk 了。"
