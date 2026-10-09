# 刮成百亿富翁

像素风 2D 刮刮乐增量游戏。当前进度：可玩的手感 Demo（垂直切片）。

界面文案为英文，工程名 `Scratch to Billions`；所有金额统一 `100.000.00` 格式。

中英双语已接入：标题页的 LANGUAGE 按钮或 `L` 键切换，选择会写入存档；
首次启动跟随系统语言。翻译表在 `localization/zh_CN.po`。

## 运行

```bash
# 编辑器
/Applications/Godot_mono.app/Contents/MacOS/Godot --path .

# 直接跑
/Applications/Godot_mono.app/Contents/MacOS/Godot --path . --editor
```

无头自检与截图验证：

```bash
Godot --headless --path . --quit-after 120
Godot --path . -- --shot-title      # 标题页截图
Godot --path . -- --shot-intro      # 过场动画截图
Godot --path . -- --shot-flow       # 全流程自检：新游戏 → 过场 → 游戏
Godot --path . -- --shot-mid        # 半刮状态截图
Godot --path . -- --shot-win        # 中奖演出席截图
Godot --path . -- --shot-jackpot    # 头奖演出席截图
Godot --headless --path . --script res://tools/analyze_shot.gd -- res://debug/win.png
```

截图输出在 `debug/`（已加入 gitignore）。

## Demo 操作

- 按住鼠标左键在票面上拖动：刮开银色涂层
- 刮开约 45%：自动清屏并结算
- 空格 / 点击「NEXT TICKET」：买下一张票
- `ESC` / 点击「MENU」：回标题页（自动存档）
- 点击「SKILLS」：进技能树花技能点（每级 +3 点）
- 点击「ALMANAC」：看图鉴与生涯统计
- `L`（标题页）：中英切换
- `J`：下一张必出锦鲤头奖（调试）
- `K`：下一张必出差一点（调试）

## 成长与难度曲线

前期刻意做得难，后期一路变解压：

| 指标 | 开局 | 满技能 |
| --- | --- | --- |
| 中奖率 | 7%（1×1 幸运卡） | 17%（9×9 八十一格卡） |
| 返奖率 | 54% | 约 326% |
| 刮擦笔刷 | 5 像素 | 11 像素 |
| 自动刮卡 | 无 | 全自动（自动清屏） |
| 差一点补偿 | 0 | 200.00 |
| 可选票种 | 只有 1×1 | 1×1 ~ 9×9 |

九个技能：TICKET SHELF（解锁更大票种）/ SHARP EDGE / AUTO SCRATCH /
LUCKY FINGERS / GOLDEN TOUCH / FRUGAL GUY / JACKPOT FEED / SOFT LANDING / MENTOR。

保底与兜底：连输 7 张必回一张小奖；没钱时直接送免费票，游戏不会卡死。
1×1 票的前三张固定中奖（教学）。

## 场景结构

| 场景 | 文件 | 说明 |
| --- | --- | --- |
| 标题页 | `scenes/title.tscn` | 摊位夜景、灯笼摆动、金币粒子、NEW GAME / CONTINUE / QUIT |
| 过场动画 | `scenes/cutscene.tscn` | 章节卡片 + 打字机字幕 + 镜头漂移，文案见 `scripts/story.gd` |
| 游戏主场景 | `scenes/game.tscn` | 刮卡、结算、奖池、HUD |
| 技能树 | `scenes/skills.tscn` | 八个技能的升级面板，技能点来自升级 |
| 图鉴 | `scenes/almanac.tscn` | 七种图案的收集状态与生涯统计 |

- `SceneDirector`（autoload）：场景切换 + 像素溶解转场（Bayer 抖动蒙版）
- `GameState`（autoload）：金额、统计与存档（`user://save.json`）
- `Music`（autoload）：程序合成的芯片音乐（五声音阶），标题与游戏各一首，
  首个输入后开声；标题页可开关（快捷键 `M`），设置存入存档

## 移动端

- 触摸输入：手指按住拖动即可刮卡（`InputEventScreenTouch` / `ScreenDrag`），
  过场动画点击屏幕任意处继续；按钮全部可直接点按
- 屏幕设置：横屏 `sensor_landscape`；内部分辨率 640×360，保持宽高比缩放，
  刘海与挖孔区域会落在黑边里，不会遮住界面
- 关闭了 `input_devices/pointing/emulate_mouse_from_touch`，避免一次触摸被当成
  两次输入
- 移动端自动切换提示文案（`TOUCH AND DRAG TO SCRATCH`），并隐藏键盘调试提示
- 输入自检：`--shot-touch --mobile`（模拟手指刮卡）与 `--shot-mouse`（鼠标对照）
- 导出：Godot 4.7 需先安装 Android 构建模板（编辑器 → 编辑器菜单 → 管理导出模板），
  再配置 Android SDK 路径即可导出 APK / AAB；iOS 需要 Xcode 与签名

## 网页端

已配置 Web 导出预设（`export_presets.cfg`），开箱即可导出。

**注意**：Godot 的 .NET（C#）版不支持导出 Web，必须用标准版编辑器；本项目是纯
GDScript，用标准版导出即可。

```bash
# 命令行导出（标准版 Godot）
Godot --headless --path . --export-release "Web" build/web/index.html

# 本地预览
python3 tools/serve_web.py 8060      # 打开 http://localhost:8060/
```

编辑器里则是：项目 → 导出 → 添加「Web」预设 → 安装导出模板 → 导出项目。

要点：

- 渲染器为 GL Compatibility（已配置），浏览器需要支持 WebGL2
- 预设里关闭了线程支持（`variant/thread_support=false`），单线程构建不依赖
  COOP/COEP 响应头，GitHub Pages 这类静态托管可直接使用；若开启线程，用
  `tools/serve_web.py` 或自行配置这两个响应头
- 不能直接双击 `index.html`：浏览器不允许 `file://` 加载 wasm/pck，必须走 HTTP
- 存档 `user://save.json` 存在浏览器 IndexedDB 里，刷新与关闭标签页都不会丢
- 鼠标与触摸都支持，页面会自适应窗口，整数缩放保持像素锐利
- 缩放使用 `fractional`：小窗口 / 高 DPI 屏幕上也能填满画面（整数缩放在这种
  情况下会把游戏缩得极小）

首屏体积（gzip 后的实际传输量）：

| 文件 | 原始 | gzip |
| --- | --- | --- |
| `index.wasm` | 37.7 MB | 9.8 MB |
| `index.pck` | 4.8 MB | 2.9 MB |
| `index.js` | 0.27 MB | 0.08 MB |

`index.pck` 已经做过瘦身：像素字体按项目实际用字裁剪（6.7 MB → 110 KB），
没用到的音效素材移出打包范围，`debug/`、`build/`、`tools/` 也被排除。
改动文案后请重新裁剪字体并校验，否则新字会显示成方块：

```bash
python3 -m venv .venv && .venv/bin/pip install fonttools
.venv/bin/python tools/subset_font.py
Godot --headless --path . --script res://tools/check_font.gd
```

## 部署

### GitHub Pages（已配置自动部署）

推送到 `main` 就会触发 `.github/workflows/deploy-web.yml`：
克隆仓库 → 打包 `build/web/` → 发布到 Pages。线上地址：

<https://lionelwangs.github.io/lionel-game/>

首次需要仓库管理员在 Settings → Pages 里把 Source 选成 «GitHub Actions»，
之后每次 `git push` 都会自动更新。手动触发：Actions → Deploy Web Build → Run workflow。

### Cloudflare Pages（国内访问更快）

GitHub Pages 走的是 Fastly 日本节点，国内直连经常只有几十 KB/s，`index.wasm`
就下不动了。Cloudflare 的免费套餐自带 Brotli 压缩和香港/日本/新加坡节点，
同一条线路实测快数倍。整站是静态文件，直接部署 `build/web` 即可：

```bash
npx wrangler pages deploy build/web --project-name lionel-game
```

首次运行会打开浏览器要求登录 Cloudflare 账号（免费注册）。部署完成后可以绑定
自己的域名，再配合「优选 IP」进一步提速。仓库里的 `build/web/_headers` 会告诉
Cloudflare 给 wasm/pck 设置长缓存，二次进入基本秒开。

### 国内加速的现实约束

- 真正落在中国大陆的 CDN 节点（腾讯云 / 阿里云 / 七牛等）需要域名完成 ICP 备案，
  备案一般要 1~2 周；没有备案就只能走港澳台 / 新加坡 / 日本节点
- `*.pages.dev`、`*.vercel.app` 这类共享域名在国内时不时被污染，绑自定义域名更稳
- 备案 + 国内对象存储/CDN 是最快方案；不备案的话，Cloudflare Pages + 自定义域名
  是免费方案里性价比最高的
- 第三方 GitHub 反代（gh-proxy 等）只适合临时救急，随时可能失效

## 本地化

- 代码里所有面向玩家的文字都走 `tr("English text")`，英文原文就是 key，
  缺翻译时自动回退英文
- 中文翻译在 `localization/zh_CN.po`，由 Godot 的 PO 导入器生成翻译资源
  （已在 `project.godot` 的 `internationalization/locale/translations` 注册）
- 新增文案：代码写 `tr("...")`，PO 里加一条 `msgid`/`msgstr`；
  带参数的用 `%s`/`%d`，中英两边占位符必须一致
- 自检：`Godot --headless --path . --script res://tools/test_locale.gd`

## 玩法数值

九个票种按网格分档，1×1 起步，用技能「TICKET SHELF」逐级解锁到 9×9：

| 票种 | 网格 | 价格 | 中奖率 | 基础返奖率 |
| --- | --- | --- | --- | --- |
| LUCKY CARD | 1×1 | 10.00 | 7% | 54% |
| QUAD CARD | 2×2 | 25.00 | 8% | 62% |
| NINE CARD | 3×3 | 60.00 | 8% | 63% |
| SIXTEEN CARD | 4×4 | 150.00 | 8% | 64% |
| TWENTY-FIVE CARD | 5×5 | 400.00 | 8% | 64% |
| THIRTY-SIX CARD | 6×6 | 1.000.00 | 8% | 67% |
| FORTY-NINE CARD | 7×7 | 2.500.00 | 9% | 70% |
| SIXTY-FOUR CARD | 8×8 | 6.000.00 | 10% | 75% |
| EIGHTY-ONE CARD | 9×9 | 15.000.00 | 11% | 82% |

中奖规则：1×1 刮出图案即中奖（空白表示没中）；2×2 及以上连成一条线
（行 / 列 / 对角线）即中奖。奖级按票价倍率 ×1 / ×3 / ×8 / ×25 / ×80 / ×250 / 头奖，
每档独立奖池滚存，每张票抽 5% 进对应奖池。

游戏里点「TICKET SHELF」打开货架切换票种，未解锁的档位会显示所需技能等级。

完整设计见 `docs/design.md`。

## 目录结构

```
scenes/title.tscn     标题页
scenes/cutscene.tscn  过场动画
scenes/game.tscn      游戏主场景
scripts/title.gd      标题页逻辑
scripts/cutscene.gd   过场播放（打字机、跳过、自动推进）
scripts/game.gd       刮卡流程、HUD、演出
scripts/skills_scene.gd 技能树场景
scripts/almanac.gd    图鉴与生涯统计
scripts/skills.gd     技能数据与效果换算
scripts/scene_director.gd 场景切换与像素溶解转场
scripts/game_state.gd 全局状态与存档
scripts/story.gd      过场文案
scripts/scene_art.gd  程序化像素场景（摊位夜景、卡片特写）
scripts/ui.gd         像素 UI 工厂（标签、按钮、金额格式）
scripts/scratch_card.gd  涂层擦除、进度、自动清屏
scripts/prize.gd      票面与奖项生成
scripts/pixel_art.gd  调色板与 16x16 符号像素图
scripts/audio_factory.gd 程序合成音效（兜底）
tools/analyze_shot.gd 截图颜色自检
tools/dump_ascii.gd   截图转字符画（文本环境核对渲染）
tools/row_hist.gd     按行统计颜色，定位 UI 元素
tools/check_font.gd   像素字体字形覆盖检查
tools/subset_font.py  按项目用字裁剪字体（需 fonttools）
tools/pck_list.py     列出导出 pck 里的文件与体积
tools/serve_web.py    本地静态服务器（带正确的 MIME 与 COOP/COEP 头）
tools/test_scratch.gd 无头刮卡流程自检
tools/test_progression.gd 无头等级与技能自检
tools/test_tiers.gd   票种生成不变量与实测概率
assets/audio/sfx/     实际打包进游戏的 4 个音效（CC0）
assets/audio/source/  完整 Kenney 音效包（.gdignore，不参与打包）
assets/fonts/         运行时像素字体（已裁剪）
assets/fonts/source/  完整字体源文件（.gdignore，不参与打包）
docs/design.md        设计定稿
```

## 素材来源与授权

- Kenney Casino Audio（CC0）：完整包在 `assets/audio/source/kenney_casino/`，
  游戏用的是 `assets/audio/sfx/sfx-scratch.ogg`
- Kenney Music Jingles（CC0）：完整包在 `assets/audio/source/kenney_jingles/`，
  游戏用的是 `assets/audio/sfx/sfx-win-*.ogg`；授权文件见两个目录内的 License.txt
- 缝合像素字体 12px（SIL OFL 1.1）：运行时是裁剪版
  `assets/fonts/fusion_pixel_12px_zh_cn.ttf`，完整字体留在
  `assets/fonts/source/`，授权文件在 `assets/fonts/fusion-pixel-licenses/`；
  未就绪时回退到系统字体
- 票面符号、票面纹理：自绘（`scripts/pixel_art.gd` 内的字符网格）
- 背景音乐：程序合成（`scripts/music_factory.gd`），无外部素材、无授权问题

## 待办

- 中奖音效已接入 Kenney 8-bit 套装（小奖 NES09 / 头奖 NES12 / 差一点 NES07），
  待实际试听后微调
- 刮擦噪音目前是程序合成，待找 CC0 沙沙声素材替换
- 章节系统（路边摊 → 小店 → 连锁店 → 彩票帝国）与终局演出（正式版范围）
