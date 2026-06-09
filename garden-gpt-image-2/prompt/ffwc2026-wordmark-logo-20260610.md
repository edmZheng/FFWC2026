# FFWC2026 创意字样 Logo（透明底 PNG，用于黑底欢迎页）

## Prompt（直接复制使用）

A premium sports wordmark logo for "FFWC2026" — exact spelling, all characters present: F, F, W, C, 2, 0, 2, 6. Single horizontal lockup, logotype only, no slogan, no extra text, no watermark.

Typography: custom geometric sans-serif with athletic energy. "FFWC" rendered in clean ultra-light strokes, wide letter spacing, pure white. "2026" rendered in massive extra-bold weight with a subtle forward italic slant, dominating the composition. The two parts share one baseline and feel like one engineered system.

2026 FIFA World Cup North America theme woven in subtly: the counter (inner hole) of the "0" in 2026 is shaped as a minimalist soccer-ball pentagon outline; a thin tri-color underline sweep in Canadian red (#E0464F), Mexican green (#2FA56B) and US blue (#4D7DEB) flows beneath "2026" like a pitch halfway-line trail. The "2026" letterforms carry a smooth vertical gradient blending these three colors — vivid and luminous, designed to glow against a pure black background.

Style: flat vector logo design, crisp edges, no 3D bevel, no drop shadow baked in, no background scenery, no mockup. Centered composition with generous margin.

Background: fully transparent (alpha PNG). If transparency is unavailable, use solid pure black #000000.

Output: 1536x1024, PNG.

## 使用提示

- GPT-Image / DALL·E：附加参数 `background: transparent`，size `1536x1024`
- Midjourney：末尾加 `--no background, mockup, shadow` 并自行抠底
- 生成后检查拼写必须是 **FFWC2026**（AI 常拼错，多生成几张挑选）

## 接入约定（给到图后由 Claude 执行）

- 放置路径：`assets/icon/ffwc_wordmark.png`（透明底优先；纯黑底也可，黑底页面无缝）
- 替换 `lib/features/splash/welcome_page.dart` 中 `_Wordmark` 为 Image.asset，宽约 240，保留测试兼容方案
