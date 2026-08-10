# 相对上游 go-music-api 做的精简

这份 `server/` 是 [guohuiyuan/go-music-api](https://github.com/guohuiyuan/go-music-api) 的一份
vendor 副本，用于交叉编译进本 App 内嵌启动。相对上游做了以下精简，目的是减小最终
交叉编译出来的二进制体积(实测 android/arm64、`-ldflags="-s -w"` 下从约 34MB 降到约 23MB)：

- 删掉了 `docs/`（swaggo 生成的 Swagger 文档数据，内嵌进 App 后不会有人拿浏览器去访问
  `/swagger/index.html`，纯粹是打包体积上的死重）。
- `router/router.go`：去掉了 Swagger UI 路由和相关 import，`gin.Default()` 换成
  `gin.New() + gin.Recovery()` 并显式设成 `ReleaseMode`（少一份内置 Logger 中间件的
  控制台日志开销，Release 模式下每次请求也会跳过 gin 自身的一些调试断言）。
- `main.go`：去掉了启动时打印 Swagger 文档地址的那行。
- `go.mod`：去掉了 `github.com/swaggo/files`、`github.com/swaggo/gin-swagger`、
  `github.com/swaggo/swag` 三个直接依赖；这仨顺带把 `go-openapi/*`、
  `KyleBanks/depth`、`golang.org/x/tools` 这些相当重的间接依赖也从最终二进制里
  砍掉了（`go.sum` 里可能还留着一些残留条目，本机跑一次 `go mod tidy` 会自动清干净，
  不影响编译，只是 go.mod 看着不够干净）。

没动业务逻辑本身，各平台的搜索/解析/流代理/歌词代码原封不动。如果之后想进一步瘦身，
可以考虑的方向（这次没做，因为会动到实际功能，需要你自己权衡取舍）：

- 按需砍掉用不到的音乐源(平台越少、`service/` 里注册的 search/parse 函数越少，
  静态链接进来的代码也越少)。
- 换用体积更小的 JSON 库或去掉暂时用不到的平台 SDK 依赖，需要读一下
  `service/` 目录下每个源具体依赖了什么。
