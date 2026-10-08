#!/usr/bin/env python3
"""本地预览网页端导出。

用法：
    python3 tools/serve_web.py [端口] [目录]
默认端口 8060，默认目录 build/web。

- 附带 COOP/COEP 响应头，兼容开启了线程支持的 Web 导出
- 修正 .wasm 的 MIME 类型，避免个别服务器按 octet-stream 下发
"""

import functools
import http.server
import os
import socketserver
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def guess_type(self, path):
        if str(path).endswith(".wasm"):
            return "application/wasm"
        return super().guess_type(path)


def main() -> None:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8060
    directory = sys.argv[2] if len(sys.argv) > 2 else "build/web"
    if not os.path.isdir(directory):
        print(f"目录不存在：{directory}（先导出 Web 版本）")
        raise SystemExit(1)
    handler = functools.partial(Handler, directory=directory)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        print(f"服务目录：{directory}")
        print(f"浏览器打开：http://localhost:{port}/")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
