const UPSTREAM_BASE = "https://raw.githubusercontent.com/charmtv/s-ui/main";
const ALLOWED_PATHS = new Set(["/install.sh", "/s-ui.sh"]);

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("仅支持 GET 和 HEAD 请求。\n", {
        status: 405,
        headers: { Allow: "GET, HEAD" },
      });
    }

    if (url.pathname === "/") {
      return new Response(
        [
          "S-UI 简体中文版",
          "",
          "一键安装：",
          "bash <(curl -Ls https://sui.813099.xyz/install.sh)",
          "",
          "项目仓库：https://github.com/charmtv/s-ui",
          "",
        ].join("\n"),
        {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "public, max-age=300",
            "X-Content-Type-Options": "nosniff",
          },
        },
      );
    }

    if (!ALLOWED_PATHS.has(url.pathname)) {
      return new Response("文件不存在。\n", { status: 404 });
    }

    try {
      const upstream = await fetch(`${UPSTREAM_BASE}${url.pathname}`, {
        method: request.method,
        headers: { Accept: "text/plain" },
        cf: {
          cacheEverything: true,
          cacheTtl: 300,
        },
      });

      const headers = new Headers(upstream.headers);
      headers.set("Content-Type", "text/plain; charset=utf-8");
      headers.set("Cache-Control", "public, max-age=300");
      headers.set("X-Content-Type-Options", "nosniff");

      return new Response(upstream.body, {
        status: upstream.status,
        statusText: upstream.statusText,
        headers,
      });
    } catch (error) {
      console.error(
        JSON.stringify({
          event: "upstream_fetch_failed",
          path: url.pathname,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
      return new Response("暂时无法获取脚本，请稍后重试。\n", { status: 502 });
    }
  },
};
