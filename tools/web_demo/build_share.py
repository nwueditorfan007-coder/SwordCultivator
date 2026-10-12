# -*- coding: utf-8 -*-
"""
打包试玩版：把 yujian_combat_proto.html 和展晏的模型、贴图打成一个单独的 HTML 文件，
朋友双击就能玩（不需要装 Python、不需要起服务器）。

做法：模型和贴图 gzip 压缩后用 base64 嵌进页面；页面打开时用浏览器自带的 DecompressionStream 解压成
blob 地址，再让模型加载器把 models/... 的请求改指向这些 blob。

只打包展晏；谢青溪的模型不打包（模型选项也会去掉）。
需要联网：three.js 和书法字体仍从 CDN 加载。

用法：python build_share.py   → 输出 dist/yujian_qiansi_demo.html
"""
import base64, gzip, io, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'yujian_combat_proto.html')
OUT_DIR = os.path.join(HERE, 'dist')
OUT = os.path.join(OUT_DIR, 'yujian_qiansi_demo.html')
MODEL_DIR = os.path.join(HERE, 'models', 'A_043_Zhanyan')


def must_replace(s, old, new):
    if s.count(old) != 1:
        sys.exit('打包失败：在页面里找不到（或找到多处）这段代码，页面结构可能改了：\n  ' + old[:80])
    return s.replace(old, new)


def main():
    html = io.open(SRC, encoding='utf-8').read()

    # 1. 收集要嵌入的文件：展晏的 FBX + 贴图（.meta 是 Unity 的附带文件，不需要）
    files = [os.path.join(MODEL_DIR, 'A_043_Zhanyan_LOD.FBX')]
    tex_dir = os.path.join(MODEL_DIR, 'Textures')
    files += [os.path.join(tex_dir, f) for f in sorted(os.listdir(tex_dir)) if f.lower().endswith('.tga')]
    embed, raw_total, packed_total = {}, 0, 0
    for path in files:
        data = open(path, 'rb').read()
        packed = gzip.compress(data, 9)
        raw_total += len(data); packed_total += len(packed)
        embed[os.path.basename(path).lower()] = base64.b64encode(packed).decode('ascii')

    # 2. 嵌入数据 + 解压脚本：放在页面主脚本之前
    entries = ',\n'.join('"%s":"%s"' % (k, v) for k, v in embed.items())
    loader_js = """<script>
// 试玩版：展晏的模型和贴图已嵌入本页（gzip + base64），打开时解压成 blob 地址，模型加载器的 models/... 请求按文件名改指向这里
window.__EMBED_URLS = {};
window.__EMBED_READY = (async () => {
  const src = {%s};
  for (const [name, b64] of Object.entries(src)) {
    const bin = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
    const blob = await new Response(new Blob([bin]).stream().pipeThrough(new DecompressionStream('gzip'))).blob();
    window.__EMBED_URLS[name] = URL.createObjectURL(blob);
  }
})().catch(e => console.warn('嵌入模型解压失败，使用程序模型', e));
</script>
""" % entries
    scripts = [m.start() for m in re.finditer(r'<script>', html)]
    if not scripts:
        sys.exit('打包失败：找不到页面主脚本')
    main_at = scripts[-1]
    html = html[:main_at] + loader_js + html[main_at:]

    # 3. 模型加载改用嵌入的数据；去掉谢青溪；等解压完再加载模型
    html = must_replace(html, '<option value="xieqingxi">谢青溪</option>', '')
    html = must_replace(html, "  xieqingxi: { name: '谢青溪', url: 'models/A_003_Xieqingxi/A_003_Xieqingxi.FBX', tex: 'models/A_003_Xieqingxi/Textures/', scale: 0.011 },\n", '')
    html = must_replace(html, "  const manager = new THREE.LoadingManager();\n",
        "  const manager = new THREE.LoadingManager();\n"
        "  if (window.__EMBED_URLS) manager.setURLModifier(u => window.__EMBED_URLS[u.split(/[\\\\/]/).pop().toLowerCase()] || u); // 试玩版：用嵌入的模型\n")
    html = must_replace(html, "\nloadModel();\n", "\n(window.__EMBED_READY || Promise.resolve()).then(loadModel);\n")

    os.makedirs(OUT_DIR, exist_ok=True)
    io.open(OUT, 'w', encoding='utf-8').write(html)
    mb = lambda n: '%.1f MB' % (n / 1048576)
    print('已生成：' + OUT)
    print('  模型贴图 %s → 压缩后 %s；页面总大小 %s' % (mb(raw_total), mb(packed_total), mb(os.path.getsize(OUT))))


if __name__ == '__main__':
    main()
