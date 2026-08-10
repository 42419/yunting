//go:build android

package main

import (
	"context"
	"net"
	"time"
)

// Android 上没有 /etc/resolv.conf，CGO_ENABLED=0 编译出来的纯 Go DNS 解析器
// 读不到系统 DNS 配置，会兜底去查 [::1]:53(本机回环地址)，导致每次域名解析都是
// "connection refused"，所有平台的搜索/解析请求第一步就挂掉。
//
// 这里直接把默认解析器的查询目标写死成一个公共 DNS，绕开"读系统配置"这一步。
// 只在交叉编译到 android 时生效(看文件头的 //go:build android)，不影响
// Docker 部署用的那份代码——那边跑在正常 Linux 环境里，/etc/resolv.conf
// 是好的，用不着这个补丁。
func init() {
	dialer := &net.Dialer{Timeout: 5 * time.Second}
	net.DefaultResolver = &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, _ string) (net.Conn, error) {
			// 223.5.5.5 是阿里云公共 DNS，国内解析速度和稳定性都不错；
			// 如果你更信任别的(比如 114.114.114.114、1.1.1.1)换掉这行就行。
			return dialer.DialContext(ctx, network, "223.5.5.5:53")
		},
	}
}
