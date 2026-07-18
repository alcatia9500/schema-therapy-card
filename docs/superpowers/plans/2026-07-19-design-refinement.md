# デザイン刷新(案A+B折衷) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 既存の `index.html` を、工芸品風カードデッキ+木目の机+整理されたタイポ+ダークモードを備えた本格的な意匠に刷新する(機能・データ形式は不変)。

**Architecture:** 変更は原則 CSS(デザイントークンの再構成、`prefers-color-scheme` によるダークモード、SVG data URI テクスチャ)と、カード面を生成する小さな共通ビルダー `cardFace()` の追加。JS ロジックの変更はチルト影用 CSS 変数の更新とアニメーション用インデックス付与のみ。

**Tech Stack:** 素のHTML5 / CSS3 / Vanilla JS。Google Fonts(Shippori Mincho)を `<link>` で読み込み、オフラインはシステム明朝にフォールバック。

## Global Constraints

- 単一ファイル `index.html`。外部依存は Google Fonts の `<link>` のみ(読めなくても機能・見た目が破綻しないこと)。`file://` で動作すること。
- localStorage キー `schemaTherapyCard.v1` とデータ形式(`sessions[].{id,title,createdAt,updatedAt,selectedCardIds,placements,view}`)を変更しない。
- 画像ファイルを追加しない。テクスチャ・紋様はインライン SVG / data URI で生成する。
- `prefers-reduced-motion: reduce` で transition と animation の両方を無効化する。
- UI文言は日本語。
- 自動テスト基盤なし。各タスクは (a) `<script>` 部を抽出して `node --check`、(b) headless Chrome スクリーンショットの目視確認で完了とする。
  - スクリプト抽出+構文チェック(以後「構文チェック」と呼ぶ):
    ```powershell
    $html = Get-Content index.html -Raw
    $js = [regex]::Match($html, '(?s)<script>(.*?)</script>').Groups[1].Value
    Set-Content -Path "C:\Users\hayashi\.claude\jobs\45a558c5\tmp\app.js" -Value $js
    node --check "C:\Users\hayashi\.claude\jobs\45a558c5\tmp\app.js"
    ```
  - スクリーンショット(以後「スクショ(名前)」と呼ぶ。ダークは `--force-dark-mode` を追加。効かない場合は一時的にメディアクエリを外したコピーで確認):
    ```powershell
    & "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless --disable-gpu --window-size=1280,900 --screenshot="C:\Users\hayashi\.claude\jobs\45a558c5\tmp\<名前>.png" "file:///C:/Users/hayashi/schemaTherapy/.claude/worktrees/design-refinement/index.html"
    ```

---

### Task 1: デザイントークン刷新とダークモード基盤

**Files:**
- Modify: `index.html`(`<head>` と `:root` 変数、既存CSS内のハードコード色、JSの領域色参照)

**Interfaces:**
- Produces: CSS変数 `--gold` `--gold-soft` `--gold-tint` `--frame` `--paper-tex` `--dom-disconnection` 等5領域色 `--desk-a/b/c` `--ui-bg` `--btn-face` `--btn-hover` `--card-ink` `--card-ink-soft`。後続タスクはこれらを参照する。
- 領域色は JS からは `var(--dom-<key>)` として参照する(`DOMAINS[].color` は使用停止)。

- [ ] **Step 1: Google Fonts の link を追加**

`<title>` の直後に:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Shippori+Mincho:wght@500;600;700&display=swap">
```

- [ ] **Step 2: `:root` を刷新しダークモードを追加**

既存 `:root` ブロックを以下で置き換える(`--serif` の先頭に "Shippori Mincho" を追加):

```css
:root {
  --paper: #f5f1e7; --card: #fbf7ec;
  --card-ink: #3a362e; --card-ink-soft: #6e675a;
  --ink: #3a362e; --ink-soft: #6e675a; --ink-faint: #9a9182;
  --line: #e2d9c6; --line-soft: #ece5d5;
  --gold: #a8845c; --gold-soft: #c3a87f; --gold-tint: rgba(168,132,92,.16);
  --frame: rgba(168,132,92,.4);
  --accent: #6f9a91; --accent-deep: #557a72; --accent-tint: rgba(111,154,145,.12);
  --dom-disconnection: #b07a52; --dom-autonomy: #649189; --dom-limits: #8d7da2;
  --dom-directedness: #6e8fa9; --dom-vigilance: #879360;
  --desk-a: #e8dfcb; --desk-b: #d8cbaf; --desk-c: #c2b090;
  --ui-bg: rgba(251,248,241,.85); --btn-face: #fffdf8; --btn-hover: #fbf8f1;
  --shadow-sm: 0 1px 2px rgba(61,58,52,.06), 0 2px 8px rgba(61,58,52,.05);
  --shadow-md: 0 4px 14px rgba(61,58,52,.10), 0 2px 6px rgba(61,58,52,.06);
  --shadow-lg: 0 18px 40px rgba(61,58,52,.22), 0 6px 14px rgba(61,58,52,.14);
  --paper-tex: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='p'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='2' seed='7'/%3E%3CfeColorMatrix values='0 0 0 0 0.42 0 0 0 0 0.36 0 0 0 0 0.26 0 0 0 0.06 0'/%3E%3C/filter%3E%3Crect width='160' height='160' filter='url(%23p)'/%3E%3C/svg%3E");
  --wood-tex: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='420' height='420'%3E%3Cfilter id='w'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.012 0.14' numOctaves='4' seed='11'/%3E%3CfeColorMatrix values='0 0 0 0 0.30 0 0 0 0 0.22 0 0 0 0 0.12 0 0 0 0.18 0'/%3E%3C/filter%3E%3Crect width='420' height='420' filter='url(%23w)'/%3E%3C/svg%3E");
  --serif: "Shippori Mincho", "Hiragino Mincho ProN", "Yu Mincho", "YuMincho", "Noto Serif JP", serif;
  --sans: system-ui, "Hiragino Kaku Gothic ProN", "Yu Gothic", "Noto Sans JP", sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root {
    --paper: #1f1c17; --card: #efe6d1;
    --ink: #d9d1c0; --ink-soft: #a89e8c; --ink-faint: #7c7466;
    --line: #3a352c; --line-soft: #2e2a23;
    --gold: #b3906a; --gold-soft: #8a7350; --gold-tint: rgba(179,144,106,.18);
    --accent: #7fa89f; --accent-deep: #93b8af; --accent-tint: rgba(127,168,159,.14);
    --dom-disconnection: #bf8a60; --dom-autonomy: #74a198; --dom-limits: #9d8db3;
    --dom-directedness: #7fa0bb; --dom-vigilance: #98a471;
    --desk-a: #4a3c2e; --desk-b: #382d21; --desk-c: #261e15;
    --ui-bg: rgba(30,27,21,.84); --btn-face: #2b2721; --btn-hover: #353026;
    --shadow-sm: 0 1px 2px rgba(0,0,0,.3), 0 2px 8px rgba(0,0,0,.25);
    --shadow-md: 0 4px 14px rgba(0,0,0,.4), 0 2px 6px rgba(0,0,0,.3);
    --shadow-lg: 0 18px 40px rgba(0,0,0,.55), 0 6px 14px rgba(0,0,0,.35);
  }
}
```

- [ ] **Step 3: ハードコード色を変数参照に置換**

- `button.secondary`: `background: var(--btn-face)`、hover `background: var(--btn-hover); border-color: var(--gold-soft)`
- `button.ghost:hover`: `background: var(--accent-tint)`
- `.banner`: `background: var(--gold-tint); border-color: var(--gold-soft); color: var(--ink)`
- `.pick-bar` / `.toolbar`: `background: var(--ui-bg)`
- `.icon-btn`: `background: var(--btn-face)`、hover `var(--btn-hover)`
- `.domain-dot` の `box-shadow` 内 `#ffffff` → `var(--paper)`
- range thumb の `border: 2px solid #fff` → `var(--btn-face)`
- `.session-item:hover` の `border-color: #ddd3c2` → `var(--gold-soft)`

- [ ] **Step 4: 領域色を CSS 変数参照に切替**

JS内の3箇所を置換:
- `renderSelect`: `style:\`--dc:${d.color}\`` → `style:\`--dc:var(--dom-${d.key})\``、`domain-dot` の `style:\`background:${d.color}\`` → `style:\`background:var(--dom-${d.key})\``
- `renderCanvas`: `style:\`--dc:${d.color}\`` → `style:\`--dc:var(--dom-${d.key})\``

`DOMAINS` から `color` プロパティを削除する。

- [ ] **Step 5: タイポスケール調整**

- `h1`: `font-size: 2rem; letter-spacing: .08em;`
- `.domain-head`: `font-size: 1.12rem; letter-spacing: .06em;`
- `.subtitle` / `.lead`: `font-size: .9rem;`

- [ ] **Step 6: 構文チェック → スクショ(t1-light, t1-dark)→ コミット**

```bash
git add index.html && git commit -m "feat: デザイントークン刷新とダークモード基盤"
```

---

### Task 2: カード意匠の共通化(縦長・番号・紋様・紙テクスチャ)

**Files:**
- Modify: `index.html`

**Interfaces:**
- Consumes: Task 1 の CSS 変数。
- Produces: JS定数 `ROMAN`(18要素の文字列配列)、`SIGILS`(領域key→SVG文字列)、`_schemaIndex`(id→通し番号)、関数 `cardFace(s)`(スキーマ1件のカード面DOMを返す)。

- [ ] **Step 1: JS にカード面ビルダーを追加**

`_domainMap` 定義の直後に追加:

```js
const ROMAN = ["Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ","Ⅶ","Ⅷ","Ⅸ","Ⅹ","Ⅺ","Ⅻ","ⅩⅢ","ⅩⅣ","ⅩⅤ","ⅩⅥ","ⅩⅦ","ⅩⅧ"];
const _schemaIndex = Object.fromEntries(SCHEMAS.map((s, i) => [s.id, i]));
const SIGILS = {
  disconnection: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M14.6 3.4a9 9 0 1 1-5.2 0" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
  autonomy: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20v-8m0 0c0-4-2.6-6.4-6.5-6.4C5.6 9.6 8 12 12 12zm0 0c0-4 2.6-6.4 6.5-6.4C18.4 9.6 16 12 12 12z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>',
  limits: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v15m-7 1h14M5 8h14M5 8l-2.4 5a2.6 2.6 0 0 0 4.8 0zM19 8l-2.4 5a2.6 2.6 0 0 0 4.8 0z" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  directedness: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="9.5" cy="12" r="5.5" fill="none" stroke="currentColor" stroke-width="1.5"/><circle cx="14.5" cy="12" r="5.5" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>',
  vigilance: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3.5 16.5l5-9 3.8 6.2 2.7-4.2 5.5 7" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
};
function cardFace(s) {
  const d = domainById(s.domain);
  const sigil = el("span", { class: "cf-sigil" });
  sigil.innerHTML = SIGILS[d.key];
  return el("div", { class: "card-face" },
    el("div", { class: "cf-head" }, sigil, el("span", { class: "cf-num" }, ROMAN[_schemaIndex[s.id]])),
    el("div", { class: "cf-name" }, s.name),
    el("span", { class: "cf-sep" }),
    el("div", { class: "cf-desc" }, s.desc),
    el("div", { class: "cf-domain" }, d.label)
  );
}
```

- [ ] **Step 2: 選択画面カードを cardFace に切替**

`renderSelect` のカード生成を:

```js
const card = el("div", { class: "card-pick" + (chosen.has(s.id) ? " selected" : ""), style: `--dc:var(--dom-${d.key})` },
  el("span", { class: "check" }, "✓"),
  cardFace(s)
);
```

- [ ] **Step 3: 机上カードを cardFace に切替**

`renderCanvas` のカード生成を:

```js
const piece = el("div", { class: "card-piece", style: `--dc:var(--dom-${d.key})` }, cardFace(s));
```

- [ ] **Step 4: カードのCSSを刷新**

`.card-pick .cname` `.cdesc`、`.card-piece .pdomain` `.pname` `.pdesc` のルールを削除し、以下に置き換え・追加:

```css
.card-face { display: flex; flex-direction: column; height: 100%; text-align: center; color: var(--card-ink); }
.cf-head { display: flex; flex-direction: column; align-items: center; gap: 2px; margin-bottom: 6px; }
.cf-sigil svg { width: 20px; height: 20px; color: var(--dc, var(--gold)); display: block; }
.cf-num { font-family: var(--serif); color: var(--gold); font-size: .78rem; letter-spacing: .14em; }
.cf-name { font-family: var(--serif); font-weight: 600; font-size: .95rem; line-height: 1.4; }
.cf-sep { width: 34px; height: 1px; background: var(--gold-soft); margin: 8px auto; position: relative; flex: none; }
.cf-sep::after { content: ""; position: absolute; left: 50%; top: 50%; width: 4px; height: 4px; background: var(--gold-soft); transform: translate(-50%,-50%) rotate(45deg); }
.cf-desc { font-size: .74rem; color: var(--card-ink-soft); line-height: 1.6; flex: 1; }
.cf-domain { font-size: .62rem; letter-spacing: .1em; color: var(--dc, var(--gold)); margin-top: 8px; opacity: .85; }
```

`.card-pick` を縦長+二重枠+紙テクスチャに(旧 `::before` 左帯は削除):

```css
.grid { grid-template-columns: repeat(auto-fill, minmax(158px, 1fr)); gap: 16px; }
.card-pick {
  position: relative; aspect-ratio: 5 / 7; padding: 18px 14px 13px;
  background: var(--card); background-image: var(--paper-tex);
  border: 1px solid rgba(120,100,70,.28); border-radius: 12px;
  box-shadow: var(--shadow-sm); cursor: pointer;
  transition: transform .14s ease, box-shadow .18s ease, border-color .18s ease;
}
.card-pick::before { content: ""; position: absolute; inset: 6px; border: 1px solid var(--frame); border-radius: 8px; pointer-events: none; }
```

`.card-piece` も同様に(旧 `border-top: 5px` を削除):

```css
.card-piece {
  position: absolute; width: 150px; height: 210px; margin-left: -75px; margin-top: -105px;
  background: var(--card); background-image: var(--paper-tex);
  border: 1px solid rgba(93,79,58,.3); border-radius: 10px; padding: 16px 13px 11px;
  cursor: grab; user-select: none;
}
.card-piece::before { content: ""; position: absolute; inset: 5px; border: 1px solid var(--frame); border-radius: 6px; pointer-events: none; }
```

- [ ] **Step 5: 机上の初期配置間隔を縦長カードに合わせる**

`reconcilePlacements` の `const gapX = 170, gapY = 120;` を `const gapX = 175, gapY = 245;` に変更。

- [ ] **Step 6: 構文チェック → スクショ(t2-light, t2-dark)→ コミット**

```bash
git add index.html && git commit -m "feat: カードを縦長の工芸品風意匠に刷新"
```

---

### Task 3: 机の質感とチルト追従影

**Files:**
- Modify: `index.html`

**Interfaces:**
- Consumes: `--wood-tex` `--desk-a/b/c`(Task 1)。
- Produces: CSS変数 `--tiltf`(0〜1、viewport 要素上で JS が更新)。

- [ ] **Step 1: 机の背景を木目に**

`.canvas-view` の `background` を:

```css
background:
  var(--wood-tex),
  radial-gradient(120% 90% at 50% 6%, var(--desk-a) 0%, var(--desk-b) 48%, var(--desk-c) 100%);
```

`.canvas-view::after`(周辺減光)を強化:

```css
box-shadow: inset 0 0 260px rgba(40,28,10,.38);
background: radial-gradient(80% 70% at 50% 40%, transparent 55%, rgba(40,28,10,.16) 100%);
```

- [ ] **Step 2: チルト追従影**

`applyStageTransform()` に1行追加:

```js
viewportEl.style.setProperty("--tiltf", (v.tilt / TILT_MAX).toFixed(3));
```

`.card-piece` に影(box-shadow を差し替え):

```css
box-shadow:
  0 calc(2px + 16px * var(--tiltf, 0)) calc(10px + 22px * var(--tiltf, 0)) rgba(35,26,12,.35),
  0 2px 4px rgba(35,26,12,.18);
```

hover / dragging はさらに浮かせる:

```css
.card-piece:hover { box-shadow: 0 calc(6px + 16px * var(--tiltf, 0)) calc(16px + 22px * var(--tiltf, 0)) rgba(35,26,12,.4), 0 3px 6px rgba(35,26,12,.2); }
.card-piece.dragging { box-shadow: 0 calc(10px + 18px * var(--tiltf, 0)) calc(24px + 24px * var(--tiltf, 0)) rgba(35,26,12,.45), 0 4px 8px rgba(35,26,12,.22); }
```

- [ ] **Step 3: 構文チェック → スクショ → コミット**

```bash
git add index.html && git commit -m "feat: 机を木目質感にしチルト追従の落ち影を追加"
```

---

### Task 4: モーション

**Files:**
- Modify: `index.html`

**Interfaces:**
- Consumes: なし(独立)。
- Produces: keyframes `fade-in` `card-rise` `card-deal`。カード要素は CSS 変数 `--i`(表示順)を持つ。

- [ ] **Step 1: keyframes と適用ルールを追加**

```css
@keyframes fade-in { from { opacity: 0; } }
@keyframes card-rise { from { opacity: 0; transform: translateY(10px); } }
@keyframes card-deal { from { opacity: 0; transform: translateY(16px) scale(1.06); } }
.wrap, .canvas-view, .toolbar { animation: fade-in .18s ease both; }
.card-pick { animation: card-rise .35s ease backwards; animation-delay: calc(var(--i, 0) * 24ms); }
.card-piece { animation: card-deal .4s cubic-bezier(.22,.9,.34,1) backwards; animation-delay: calc(var(--i, 0) * 55ms); }
```

`prefers-reduced-motion` を拡張:

```css
@media (prefers-reduced-motion: reduce) { * { transition: none !important; animation: none !important; } }
```

- [ ] **Step 2: JS で表示順 `--i` を付与**

- `renderSelect`: 全領域を通した連番カウンタ `let pickIndex = 0;` をループ外に置き、カード生成の `style` に `;--i:${pickIndex++}` を追記。
- `renderCanvas`: `for (const id of ...)` を index つきループにし、`style` に `;--i:${i}` を追記。

- [ ] **Step 3: ドラッグ中の演出**

`.card-piece.dragging` の transform を `scale(1.05) rotate(.8deg)` に。

- [ ] **Step 4: 構文チェック → スクショ → コミット**

```bash
git add index.html && git commit -m "feat: 画面遷移とカードのモーションを追加"
```

---

### Task 5: 各画面の磨き込み(飾り罫・色チップ・章扉見出し)

**Files:**
- Modify: `index.html`

**Interfaces:**
- Consumes: `SIGILS`(Task 2)、`--dom-*`(Task 1)。

- [ ] **Step 1: 飾り罫(ornament)**

CSS:

```css
.ornament { display: flex; align-items: center; gap: 10px; width: min(240px, 60%); margin: 14px 0 0; color: var(--gold-soft); }
.ornament::before, .ornament::after { content: ""; flex: 1; height: 1px; background: currentColor; opacity: .7; }
.ornament i { width: 5px; height: 5px; background: currentColor; transform: rotate(45deg); flex: none; }
```

`renderHome` と `renderSelect` の `.page-head` 末尾に `el("div", { class:"ornament" }, el("i"))` を追加。

- [ ] **Step 2: セッション一覧の領域色チップ**

CSS:

```css
.chips { display: flex; gap: 4px; margin-top: 7px; align-items: center; }
.chip { width: 10px; height: 14px; border-radius: 2px; display: inline-block; }
.chip-more { font-size: .7rem; color: var(--ink-faint); margin-left: 2px; }
```

`renderHome` のセッション項目 `.meta` 内(`small` の後)に:

```js
if (s.selectedCardIds.length) {
  const chips = el("span", { class: "chips" });
  s.selectedCardIds.slice(0, 8).forEach(cid => {
    const dk = schemaById(cid) ? schemaById(cid).domain : null;
    if (dk) chips.appendChild(el("i", { class: "chip", style: `background:var(--dom-${dk})` }));
  });
  if (s.selectedCardIds.length > 8) chips.appendChild(el("span", { class: "chip-more" }, "+" + (s.selectedCardIds.length - 8)));
  meta.appendChild(chips);
}
```

(`.meta` を変数 `meta` として組み立てる形にリファクタする。)

- [ ] **Step 3: 領域見出しを章扉風に**

`renderSelect` の `domain-head` を `domain-dot` の代わりに紋様で:

```js
const dh = el("div", { class: "domain-head", style: `--dc:var(--dom-${d.key})` });
const dsig = el("span", { class: "dh-sigil" });
dsig.innerHTML = SIGILS[d.key];
dh.append(dsig, document.createTextNode(d.label));
```

CSS(`.domain-dot` ルールは削除):

```css
.domain-head::after { content: ""; flex: 1; height: 1px; background: var(--line); margin-left: 6px; }
.dh-sigil { display: inline-flex; color: var(--dc, var(--gold)); }
.dh-sigil svg { width: 18px; height: 18px; }
```

- [ ] **Step 4: 構文チェック → スクショ(home含む)→ コミット**

```bash
git add index.html && git commit -m "feat: 飾り罫・領域色チップ・章扉風見出しを追加"
```

---

### Task 6: 総合検証・レビュー・公開

**Files:**
- なし(検証のみ。指摘があれば `index.html` を修正)

- [ ] **Step 1: 3画面 × ライト/ダークのスクショを取得し目視確認**

- 選択画面: localStorage なしで初期表示がそのまま選択画面。
- ホーム/机: `index.html` のコピーを tmp に作り、`loadDB();` の直前にデモデータ注入コードを挿入して撮影:

```js
try { localStorage.setItem("schemaTherapyCard.v1", JSON.stringify({ version: 1, sessions: [{
  id: "demo", title: "デモワーク", createdAt: "2026-07-19T00:00:00.000Z", updatedAt: "2026-07-19T00:00:00.000Z",
  selectedCardIds: ["abandonment","mistrust","failure","subjugation","punitiveness","unrelenting-standards"],
  placements: { abandonment:{x:-180,y:-130,z:1}, mistrust:{x:0,y:-130,z:2}, failure:{x:180,y:-130,z:3},
    subjugation:{x:-180,y:130,z:4}, punitiveness:{x:0,y:130,z:5}, "unrelenting-standards":{x:180,y:130,z:6} },
  view: { zoom: 1, tilt: 35, panX: 0, panY: 0 } }] })); } catch (e) {}
```

机画面はさらに `state.currentSessionId = "demo"; state.screen = "canvas";` を起動分岐の後に強制する行を注入。

確認観点: ダークでカードが紙色のまま読めるか、チルト35°で影が伸びているか、内枠・番号・紋様が崩れていないか、選択画面の18枚が破綻なく並ぶか。

- [ ] **Step 2: コードレビュー(サブエージェント)**

superpowers:requesting-code-review の流儀で、`main` との diff をサブエージェントにレビューさせ、Critical/Important な指摘を修正する。

- [ ] **Step 3: main へ ff-merge して push、Pages 反映確認**

```powershell
git -C C:\Users\hayashi\schemaTherapy checkout main
git -C C:\Users\hayashi\schemaTherapy merge --ff-only worktree-design-refinement
git -C C:\Users\hayashi\schemaTherapy push origin main
```

(既存フロー踏襲。deploy 手順の詳細は memory `schema-therapy-card-deploy` を参照。)
