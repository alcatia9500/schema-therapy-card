# スキーマ療法カード・ワークスペース Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ヤングの18スキーマを1枚ずつカード化し、選択→机の上に3D俯瞰で自由配置してワークできる、依存ゼロの単一HTMLセルフヘルプツールを作る。

**Architecture:** `index.html` 1ファイルに CSS / JavaScript / カードデータをすべて内包する。状態変数と `render()` によるセクション表示切替の素朴なSPA。3D表現は viewport 要素の `perspective` + 机(stage)要素の `rotateX/scale/translate` で実現し、カードは stage の絶対配置の子。永続化は localStorage に全状態をデバウンス書き戻し。

**Tech Stack:** 素のHTML5 / CSS3 (3D transform) / Vanilla JavaScript (ES2020, Pointer Events)。ライブラリ・ビルド・Node.js は一切使わない。

## Global Constraints

- 出力は単一ファイル `index.html` のみ。外部ライブラリ・CDN・ビルド工程を使わない。`file://` でダブルクリック起動して動くこと。
- 外部ネットワーク送信を一切行わない。データは localStorage のみに保存する。
- localStorage キーは `schemaTherapyCard.v1`、バックアップキーは `schemaTherapyCard.v1.backup`。
- データモデルのフィールド名は設計書どおり: `sessions[].{id,title,createdAt,updatedAt,selectedCardIds,placements,view}`、`placements[cardId]={x,y,z}`、`view={zoom,tilt,panX,panY}`。
- カード本文は保存しない(IDのみ保存)。本文はデッキ定数 `SCHEMAS` から引く。
- ズーム範囲 0.3〜3.0、チルト範囲 0〜60°。
- UI文言は日本語。
- 自動テスト基盤は持たない。各タスクは実装後に `index.html` をブラウザで開いて手動検証チェックリストを満たすことで完了とする。

---

### Task 1: プロジェクト骨格とデッキデータ

**Files:**
- Create: `index.html`

**Interfaces:**
- Produces:
  - グローバル定数 `SCHEMAS`: 18要素の配列。各要素 `{ id:string, name:string, domain:string, desc:string }`。`id` は英小文字ケバブ、`domain` は5領域のいずれかのキー。
  - グローバル定数 `DOMAINS`: `{ key:string, label:string, color:string }` の5要素配列(領域見出しとテーマカラー)。
  - `<div id="app"></div>` を含む最小HTML骨格と `<style>` `<script>` ブロック。

- [ ] **Step 1: HTML骨格を作る**

`index.html` を新規作成し、以下の骨格を書く。

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>スキーマ療法カード</title>
<style>
  * { box-sizing: border-box; }
  body { margin: 0; font-family: system-ui, "Hiragino Kaku Gothic ProN", "Yu Gothic", sans-serif; background:#f2efe9; color:#2b2b2b; }
  #app { min-height: 100vh; }
</style>
</head>
<body>
<div id="app"></div>
<script>
"use strict";
// ==== デッキデータ (Task 1) ====
// ==== 状態と永続化 (Task 2) ====
// ==== レンダリング (Task 3以降) ====
</script>
</body>
</html>
```

- [ ] **Step 2: 5領域の定数を書く**

`<script>` のデッキデータ節に追加。

```js
const DOMAINS = [
  { key: "disconnection", label: "I. 断絶と拒絶", color: "#b5651d" },
  { key: "autonomy",      label: "II. 自律性と行動の損傷", color: "#3a7d7b" },
  { key: "limits",        label: "III. 制約の欠如", color: "#8a6d9e" },
  { key: "directedness",  label: "IV. 他者への追従", color: "#4a7ba6" },
  { key: "vigilance",     label: "V. 過剰警戒と抑制", color: "#7a8c46" },
];
```

- [ ] **Step 3: 18スキーマの定数を書く**

`DOMAINS` の直後に追加。説明文は平易な日本語2〜3文。

```js
const SCHEMAS = [
  { id:"abandonment", name:"見捨てられ／不安定", domain:"disconnection",
    desc:"支えてくれる人はいずれ去る、頼れない、と感じる。人との別れや不在に強い不安を覚える。" },
  { id:"mistrust", name:"不信／虐待", domain:"disconnection",
    desc:"他人はいつか自分を傷つけ、利用し、裏切ると身構える。人の善意を素直に受け取りにくい。" },
  { id:"emotional-deprivation", name:"情緒的剥奪", domain:"disconnection",
    desc:"必要な愛情・理解・保護が得られないと感じる。心の中がいつも満たされない。" },
  { id:"defectiveness", name:"欠陥／恥", domain:"disconnection",
    desc:"自分は欠けていて価値がない、知られたら見捨てられると感じる。強い恥や自己否定を伴う。" },
  { id:"social-isolation", name:"社会的孤立／疎外", domain:"disconnection",
    desc:"自分はどの集団にも属せない、みんなと違う、と感じて孤立感を抱く。" },
  { id:"dependence", name:"依存／無能", domain:"autonomy",
    desc:"助けなしには日常をこなせないと感じる。判断や行動を人に委ねがちになる。" },
  { id:"vulnerability", name:"危険や病気に対する脆弱性", domain:"autonomy",
    desc:"いつ災難・病気・破滅が起きるか分からないと過度に恐れ、備えや心配が絶えない。" },
  { id:"enmeshment", name:"巻き込まれ／未発達の自己", domain:"autonomy",
    desc:"身近な人と過度に一体化し、自分自身の考えや方向性が育ちにくい。" },
  { id:"failure", name:"失敗", domain:"autonomy",
    desc:"自分は同世代より劣り、何をやっても失敗すると感じる。挑戦を避けがちになる。" },
  { id:"entitlement", name:"権利要求／尊大", domain:"limits",
    desc:"自分は特別で制約を受けないと感じる。他者への配慮より自分の要求を優先しやすい。" },
  { id:"insufficient-self-control", name:"自制と自律の欠如", domain:"limits",
    desc:"退屈や不快に耐えるのが難しく、衝動や感情を抑えて目標を追うのが苦手。" },
  { id:"subjugation", name:"服従", domain:"directedness",
    desc:"衝突や見捨てを避けるため、自分の欲求や感情を抑えて他者に従ってしまう。" },
  { id:"self-sacrifice", name:"自己犠牲", domain:"directedness",
    desc:"他者の苦痛を放っておけず、自分の必要を後回しにして尽くしすぎてしまう。" },
  { id:"approval-seeking", name:"評価と承認の希求", domain:"directedness",
    desc:"他者からの評価・承認を過度に求め、それに合わせて自分を形づくってしまう。" },
  { id:"negativity", name:"否定／悲観", domain:"vigilance",
    desc:"物事の悪い面ばかりに目が向き、うまくいかない未来を強く予期してしまう。" },
  { id:"emotional-inhibition", name:"感情抑制", domain:"vigilance",
    desc:"怒り・喜び・弱さなどの感情や衝動を、恥や制御のために抑え込んでしまう。" },
  { id:"unrelenting-standards", name:"厳密な基準／過度の批判", domain:"vigilance",
    desc:"非常に高い基準を自分(や他者)に課し、決して十分と思えず自分を厳しく批判する。" },
  { id:"punitiveness", name:"罰", domain:"vigilance",
    desc:"過ちは厳しく罰せられるべきだと考え、自分や他者のミスに寛容になれない。" },
];
```

- [ ] **Step 4: ブラウザで手動検証**

`index.html` をブラウザで開き、開発者コンソールで確認する。
- `SCHEMAS.length` → `18`
- `DOMAINS.length` → `5`
- `SCHEMAS.every(s => DOMAINS.some(d => d.key === s.domain))` → `true`
- `new Set(SCHEMAS.map(s=>s.id)).size` → `18`(ID重複なし)
- ページが白紙で表示されエラーが出ないこと。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: HTML骨格と18スキーマ・5領域のデッキデータを追加"
```

---

### Task 2: 状態・localStorage永続化・ID生成

**Files:**
- Modify: `index.html`(`<script>` の「状態と永続化」節)

**Interfaces:**
- Consumes: `SCHEMAS`(Task 1)
- Produces:
  - グローバル `state`: `{ db:{version:1,sessions:[]}, currentSessionId:string|null, screen:"home"|"select"|"canvas", storageOK:boolean }`。
  - `genId(): string` — 時刻+乱数ベースの一意文字列。
  - `loadDB(): void` — localStorage から `state.db` を読み込む。壊れていればバックアップ退避+初期化、使えなければ `state.storageOK=false`。
  - `saveDB(): void` — `state.db` を localStorage に即時書き込み(失敗は握りつぶさず警告)。
  - `scheduleSave(): void` — 500msデバウンスで `saveDB()` を呼ぶ。
  - `getSession(id): object|null` / `getCurrentSession(): object|null`。
  - `touchSession(session): void` — `updatedAt` を現在時刻に更新。

- [ ] **Step 1: 状態オブジェクトとID生成を書く**

```js
const STORAGE_KEY = "schemaTherapyCard.v1";
const BACKUP_KEY = "schemaTherapyCard.v1.backup";
const ZOOM_MIN = 0.3, ZOOM_MAX = 3.0, TILT_MIN = 0, TILT_MAX = 60;

const state = {
  db: { version: 1, sessions: [] },
  currentSessionId: null,
  screen: "home",
  storageOK: true,
};

function genId() {
  return Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
}
```

- [ ] **Step 2: 読み込み・保存関数を書く**

```js
function loadDB() {
  let raw;
  try {
    raw = localStorage.getItem(STORAGE_KEY);
  } catch (e) {
    state.storageOK = false;
    return;
  }
  if (!raw) return;
  try {
    const parsed = JSON.parse(raw);
    if (parsed && parsed.version === 1 && Array.isArray(parsed.sessions)) {
      state.db = parsed;
    } else {
      throw new Error("unexpected shape");
    }
  } catch (e) {
    try { localStorage.setItem(BACKUP_KEY, raw); } catch (_) {}
    state.db = { version: 1, sessions: [] };
    state.corrupted = true;
  }
}

function saveDB() {
  if (!state.storageOK) return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state.db));
    state.saveError = false;
  } catch (e) {
    state.saveError = true;
  }
}

let _saveTimer = null;
function scheduleSave() {
  if (_saveTimer) clearTimeout(_saveTimer);
  _saveTimer = setTimeout(saveDB, 500);
}
```

- [ ] **Step 3: セッション補助関数を書く**

```js
function getSession(id) {
  return state.db.sessions.find(s => s.id === id) || null;
}
function getCurrentSession() {
  return getMaybe(state.currentSessionId);
}
function getMaybe(id) {
  return id ? getSession(id) : null;
}
function nowISO() {
  return new Date().toISOString();
}
function touchSession(session) {
  session.updatedAt = nowISO();
}
```

- [ ] **Step 4: 起動時に読み込む**

`<script>` の末尾(全関数定義の後になる位置。今はレンダリング前なので仮に末尾)に起動処理を置く。後続タスクで `render()` 呼び出しを足す。

```js
// ==== 起動 ====
loadDB();
```

- [ ] **Step 5: ブラウザで手動検証**

`index.html` を開き、コンソールで確認する。
- `state.db` → `{version:1, sessions:[]}`
- `genId() !== genId()` → `true`
- 手動で `state.db.sessions.push({id:"t"}); saveDB();` 実行後にリロード → `loadDB()` 済みの `state.db.sessions[0].id` が `"t"` になる(=保存/復元が往復する)。確認後 `localStorage.removeItem(STORAGE_KEY)` で掃除する。

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "feat: 状態管理とlocalStorage永続化・ID生成を追加"
```

---

### Task 3: ルーターとホーム画面(セッション一覧)

**Files:**
- Modify: `index.html`(`<style>` とレンダリング節)

**Interfaces:**
- Consumes: `state`, `getSession`, `saveDB`, `genId`, `nowISO`, `SCHEMAS`(Task 1-2)
- Produces:
  - `render(): void` — `state.screen` を見て対応画面を `#app` に描画する中央ディスパッチャ。
  - `renderHome(): void` — セッション一覧を描画。
  - `createSession(): string` — 新規セッションを `state.db.sessions` に追加し、その id を返す。`title` は既定 `"YYYY-MM-DD のワーク"`、`selectedCardIds:[]`, `placements:{}`, `view:{zoom:1,tilt:0,panX:0,panY:0}`。
  - `deleteSession(id): void` — 確認のうえ削除して再描画。
  - `go(screen): void` — `state.screen` を設定して `render()`。

- [ ] **Step 1: 共通ボタン等のスタイルを追加**

`<style>` に追記。

```css
button { font: inherit; cursor: pointer; border: none; border-radius: 8px; padding: 10px 16px; background:#3a7d7b; color:#fff; }
button.secondary { background:#e3ddd2; color:#2b2b2b; }
button:disabled { opacity:.45; cursor:not-allowed; }
.wrap { max-width: 900px; margin: 0 auto; padding: 24px 16px 80px; }
h1 { font-size: 1.4rem; }
.banner { background:#f6e2c9; border:1px solid #d9b98a; padding:10px 14px; border-radius:8px; margin-bottom:16px; font-size:.9rem; }
.session-item { display:flex; align-items:center; gap:12px; background:#fff; border:1px solid #e2ddd2; border-radius:12px; padding:14px 16px; margin-bottom:10px; }
.session-item .meta { flex:1; }
.session-item .meta small { color:#777; }
.empty { color:#777; padding:24px 0; }
```

- [ ] **Step 2: ルーターとgoを書く**

```js
function go(screen) {
  state.screen = screen;
  render();
}

function render() {
  const app = document.getElementById("app");
  app.innerHTML = "";
  const banner = warningBanner();
  if (banner) app.appendChild(banner);
  if (state.screen === "home") renderHome(app);
  else if (state.screen === "select") renderSelect(app);
  else if (state.screen === "canvas") renderCanvas(app);
}

function warningBanner() {
  let msg = null;
  if (!state.storageOK) msg = "ブラウザの保存領域が使えません。作業はこのタブを閉じると消えます。";
  else if (state.corrupted) msg = "保存データが壊れていたため初期化しました(バックアップを退避済み)。";
  else if (state.saveError) msg = "保存に失敗しました。空き容量をご確認ください。";
  if (!msg) return null;
  const div = document.createElement("div");
  div.className = "banner";
  div.textContent = msg;
  return div;
}
```

Task 4/5 の `renderSelect` / `renderCanvas` はまだ無いので、仮スタブを一時的に置く。

```js
function renderSelect(app){ app.appendChild(el("div",{class:"wrap"},"(select 画面: Task 4)")); }
function renderCanvas(app){ app.appendChild(el("div",{class:"wrap"},"(canvas 画面: Task 5)")); }
```

- [ ] **Step 3: DOM生成ヘルパ `el` を書く**

レンダリング節の先頭に置く(全renderで使う)。

```js
function el(tag, attrs, ...children) {
  const node = document.createElement(tag);
  if (attrs) for (const k in attrs) {
    if (k === "class") node.className = attrs[k];
    else if (k === "style") node.style.cssText = attrs[k];
    else if (k.startsWith("on") && typeof attrs[k] === "function") node.addEventListener(k.slice(2), attrs[k]);
    else if (attrs[k] != null) node.setAttribute(k, attrs[k]);
  }
  for (const c of children) {
    if (c == null || c === false) continue;
    node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
  }
  return node;
}
```

- [ ] **Step 4: セッションCRUDとホーム描画を書く**

```js
function defaultTitle() {
  const d = new Date();
  const p = n => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())} のワーク`;
}

function createSession() {
  const id = genId();
  const t = nowISO();
  state.db.sessions.push({
    id, title: defaultTitle(), createdAt: t, updatedAt: t,
    selectedCardIds: [], placements: {}, view: { zoom:1, tilt:0, panX:0, panY:0 },
  });
  saveDB();
  return id;
}

function deleteSession(id) {
  if (!confirm("このワークを削除しますか?")) return;
  state.db.sessions = state.db.sessions.filter(s => s.id !== id);
  saveDB();
  render();
}

function renderHome(app) {
  const wrap = el("div", { class:"wrap" });
  wrap.appendChild(el("h1", null, "スキーマ療法カード"));
  wrap.appendChild(el("button", { onclick: () => { state.currentSessionId = createSession(); go("select"); } }, "新しいワークを始める"));

  const sessions = [...state.db.sessions].sort((a,b) => b.updatedAt.localeCompare(a.updatedAt));
  if (sessions.length === 0) {
    wrap.appendChild(el("p", { class:"empty" }, "まだワークがありません。上のボタンから始めましょう。"));
  } else {
    const list = el("div", { style:"margin-top:20px" });
    for (const s of sessions) {
      list.appendChild(el("div", { class:"session-item" },
        el("div", { class:"meta" },
          el("div", null, s.title),
          el("small", null, `${s.selectedCardIds.length}枚 ・ 更新 ${s.updatedAt.slice(0,16).replace("T"," ")}`)
        ),
        el("button", { onclick: () => { state.currentSessionId = s.id; go("canvas"); } }, "開く"),
        el("button", { class:"secondary", onclick: () => deleteSession(s.id) }, "削除")
      ));
    }
    wrap.appendChild(list);
  }
  app.appendChild(wrap);
}
```

- [ ] **Step 5: 起動処理で初回分岐を実装**

Task 2 で置いた `loadDB();` の下を次に差し替える。

```js
loadDB();
if (state.db.sessions.length === 0) {
  state.currentSessionId = createSession();
  state.screen = "select";
} else {
  state.screen = "home";
}
render();
```

- [ ] **Step 6: ブラウザで手動検証**

`localStorage.removeItem("schemaTherapyCard.v1")` してからリロード。
- セッション0件の初回 → select スタブ画面が出る(初回はホームを飛ばす)。
- コンソールで `state.currentSessionId=null; go("home")` → 「まだワークがありません」が出る。
- 「新しいワークを始める」→ select スタブへ。リロードするとホームに1件並ぶ。「開く」で canvas スタブ、「削除」で確認後に消える。

- [ ] **Step 7: Commit**

```bash
git add index.html
git commit -m "feat: ルーター・DOMヘルパ・ホーム画面(セッション一覧)を追加"
```

---

### Task 4: カード選択画面

**Files:**
- Modify: `index.html`(`<style>` とレンダリング節。`renderSelect` スタブを本実装に置換)

**Interfaces:**
- Consumes: `SCHEMAS`, `DOMAINS`, `getCurrentSession`, `el`, `go`, `saveDB`, `scheduleSave`, `touchSession`(Task 1-3)
- Produces:
  - `renderSelect(app): void` — 18枚を領域別グリッド表示。現在セッションの `selectedCardIds` を反映。選択トグル。下部固定バーに枚数と「確定」。
  - 確定時: 選択を `session.selectedCardIds` に反映し、`reconcilePlacements(session)`(Task 5で定義)を呼んでから `go("canvas")`。
  - `schemaById(id): object` — id からスキーマを引く。
  - `domainById(key): object` — key から領域を引く。

- [ ] **Step 1: 選択画面のスタイルを追加**

```css
.grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); gap:12px; }
.domain-head { grid-column:1/-1; font-weight:700; margin:18px 0 4px; padding-left:8px; border-left:5px solid; }
.card-pick { position:relative; background:#fff; border:2px solid #e2ddd2; border-radius:12px; padding:12px 14px; transition:transform .08s; }
.card-pick:hover { transform:translateY(-2px); }
.card-pick.selected { border-color:#3a7d7b; box-shadow:0 0 0 2px #3a7d7b33; }
.card-pick .cname { font-weight:700; margin-bottom:6px; }
.card-pick .cdesc { font-size:.82rem; color:#555; line-height:1.5; }
.card-pick .check { position:absolute; top:8px; right:10px; color:#3a7d7b; font-weight:700; display:none; }
.card-pick.selected .check { display:block; }
.pick-bar { position:fixed; left:0; right:0; bottom:0; background:#fffef9; border-top:1px solid #e2ddd2; display:flex; align-items:center; justify-content:space-between; gap:12px; padding:12px 16px; }
```

- [ ] **Step 2: 参照ヘルパを書く**

```js
const _schemaMap = Object.fromEntries(SCHEMAS.map(s => [s.id, s]));
const _domainMap = Object.fromEntries(DOMAINS.map(d => [d.key, d]));
function schemaById(id){ return _schemaMap[id]; }
function domainById(key){ return _domainMap[key]; }
```

- [ ] **Step 3: `renderSelect` を実装(スタブ置換)**

```js
function renderSelect(app) {
  const session = getCurrentSession();
  if (!session) { go("home"); return; }
  const chosen = new Set(session.selectedCardIds);

  const wrap = el("div", { class:"wrap" });
  wrap.appendChild(el("h1", null, "当てはまるカードを選ぶ"));
  wrap.appendChild(el("p", { style:"color:#666;margin-top:-6px" }, "今の自分に当てはまる、気になるカードを選んでください。"));

  const grid = el("div", { class:"grid" });
  for (const d of DOMAINS) {
    const head = el("div", { class:"domain-head", style:`border-color:${d.color}` }, d.label);
    grid.appendChild(head);
    for (const s of SCHEMAS.filter(x => x.domain === d.key)) {
      const card = el("div", { class:"card-pick" + (chosen.has(s.id) ? " selected" : "") },
        el("span", { class:"check" }, "✓"),
        el("div", { class:"cname" }, s.name),
        el("div", { class:"cdesc" }, s.desc)
      );
      card.addEventListener("click", () => {
        if (chosen.has(s.id)) chosen.delete(s.id); else chosen.add(s.id);
        card.classList.toggle("selected");
        count.textContent = `${chosen.size}枚選択中`;
        confirmBtn.disabled = chosen.size === 0;
      });
      grid.appendChild(card);
    }
  }
  wrap.appendChild(grid);
  app.appendChild(wrap);

  const count = el("span", null, `${chosen.size}枚選択中`);
  const confirmBtn = el("button", { onclick: () => {
    session.selectedCardIds = SCHEMAS.filter(s => chosen.has(s.id)).map(s => s.id);
    reconcilePlacements(session);
    touchSession(session);
    saveDB();
    go("canvas");
  } }, "確定");
  confirmBtn.disabled = chosen.size === 0;
  const backBtn = el("button", { class:"secondary", onclick: () => go(state.db.sessions.length ? "home" : "select") }, "ホームへ");
  app.appendChild(el("div", { class:"pick-bar" }, backBtn, count, confirmBtn));
}
```

- [ ] **Step 4: `reconcilePlacements` の暫定版を置く**

Task 5 で本実装するが、Task 4 単体で動かすため暫定版を先に置く(Task 5 で置換)。

```js
function reconcilePlacements(session) {
  // 暫定: 選択カードに placement が無ければ (0,0) を与える。Task 5 で整列配置に置換。
  let z = 1;
  const kept = {};
  session.selectedCardIds.forEach(id => {
    kept[id] = session.placements[id] || { x:0, y:0, z: z };
    z++;
  });
  session.placements = kept;
}
```

- [ ] **Step 5: ブラウザで手動検証**

- 新規ワーク開始 → 18枚が5領域の見出し付きで色分け表示される。
- カードクリックで枠が強調+✓表示、下部バーの枚数が増減する。0枚で「確定」が無効。
- 5枚選んで確定 → canvas スタブへ。ホーム→開く→(まだ選び直し導線は Task 5)だが、コンソールで `go("select")` すると選択済み5枚が反映されている。

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "feat: カード選択画面(領域別グリッド・選択トグル・確定)を追加"
```

---

### Task 5: ワークキャンバス(3D俯瞰・整列配置・選び直し整合)

**Files:**
- Modify: `index.html`(`<style>` とレンダリング節。`renderCanvas` と `reconcilePlacements` を本実装に置換)

**Interfaces:**
- Consumes: `getCurrentSession`, `schemaById`, `domainById`, `el`, `go`, `scheduleSave`, `touchSession`, `ZOOM_MIN/MAX`, `TILT_MIN/MAX`(Task 1-4)
- Produces:
  - `renderCanvas(app): void` — viewport(perspective)+ stage(3D transform)+ カード群+ツールバーを描画。
  - `reconcilePlacements(session): void`(本実装) — 継続カードは座標・z維持、新規カードは中央付近に整列配置、解除カードは削除。
  - `applyStageTransform(): void` — 現在セッションの `view` を stage の CSS transform に反映。
  - モジュール内変数 `stageEl`, `viewportEl` を保持。

- [ ] **Step 1: キャンバスのスタイルを追加**

```css
.canvas-view { position:fixed; inset:0; overflow:hidden; background:#dcd6ca; perspective:1200px; touch-action:none; }
.stage { position:absolute; left:50%; top:50%; width:0; height:0; transform-style:preserve-3d; will-change:transform; }
.card-piece { position:absolute; width:150px; min-height:96px; margin-left:-75px; margin-top:-48px;
  background:#fffdf7; border-radius:12px; border-top:6px solid #999; padding:10px 12px;
  box-shadow:0 3px 8px rgba(0,0,0,.2); cursor:grab; user-select:none; }
.card-piece.dragging { cursor:grabbing; box-shadow:0 12px 24px rgba(0,0,0,.35); }
.card-piece .pname { font-weight:700; font-size:.86rem; margin-bottom:4px; }
.card-piece .pdesc { font-size:.72rem; color:#555; line-height:1.45; }
.toolbar { position:fixed; top:12px; left:12px; right:12px; display:flex; flex-wrap:wrap; align-items:center; gap:8px;
  background:#fffef9cc; backdrop-filter:blur(4px); border:1px solid #e2ddd2; border-radius:12px; padding:8px 12px; z-index:10; }
.toolbar .spacer { flex:1; }
.toolbar label { font-size:.8rem; display:flex; align-items:center; gap:6px; }
```

- [ ] **Step 2: `reconcilePlacements` を本実装に置換**

```js
function reconcilePlacements(session) {
  const selected = session.selectedCardIds;
  const kept = {};
  let maxZ = 0;
  // 継続カード: 座標・z を維持
  selected.forEach(id => {
    if (session.placements[id]) {
      kept[id] = session.placements[id];
      maxZ = Math.max(maxZ, kept[id].z || 0);
    }
  });
  // 新規カード: 中央付近にグリッド整列
  const newIds = selected.filter(id => !kept[id]);
  const cols = Math.ceil(Math.sqrt(newIds.length)) || 1;
  const gapX = 170, gapY = 120;
  newIds.forEach((id, i) => {
    const r = Math.floor(i / cols), c = i % cols;
    const x = (c - (cols - 1) / 2) * gapX;
    const y = (r - (Math.ceil(newIds.length / cols) - 1) / 2) * gapY;
    maxZ += 1;
    kept[id] = { x, y, z: maxZ };
  });
  session.placements = kept;
}
```

- [ ] **Step 3: transform適用関数を書く**

```js
let stageEl = null, viewportEl = null;

function applyStageTransform() {
  const v = getCurrentSession().view;
  stageEl.style.transform =
    `rotateX(${v.tilt}deg) scale(${v.zoom}) translate(${v.panX}px, ${v.panY}px)`;
}

function clamp(n, lo, hi){ return Math.max(lo, Math.min(hi, n)); }
function bringToFront(session, id) {
  let maxZ = 0;
  for (const k in session.placements) maxZ = Math.max(maxZ, session.placements[k].z);
  session.placements[id].z = maxZ + 1;
}
```

- [ ] **Step 4: `renderCanvas` を実装(スタブ置換)**

```js
function renderCanvas(app) {
  const session = getCurrentSession();
  if (!session) { go("home"); return; }
  if (session.selectedCardIds.length === 0) { go("select"); return; }

  viewportEl = el("div", { class:"canvas-view" });
  stageEl = el("div", { class:"stage" });
  viewportEl.appendChild(stageEl);

  for (const id of session.selectedCardIds) {
    const s = schemaById(id);
    const p = session.placements[id];
    const piece = el("div", { class:"card-piece" },
      el("div", { class:"pname" }, s.name),
      el("div", { class:"pdesc" }, s.desc)
    );
    piece.style.borderTopColor = domainById(s.domain).color;
    piece.dataset.id = id;
    positionPiece(piece, p);
    attachCardDrag(piece, session);
    stageEl.appendChild(piece);
  }

  app.appendChild(viewportEl);
  app.appendChild(buildToolbar(session));
  applyStageTransform();
  attachViewControls(session);
}

function positionPiece(piece, p) {
  piece.style.left = p.x + "px";
  piece.style.top = p.y + "px";
  piece.style.zIndex = p.z;
}
```

- [ ] **Step 5: ツールバーを書く**

```js
function buildToolbar(session) {
  const v = session.view;
  const zoomOut = el("button", { class:"secondary", onclick: () => nudgeZoom(session, -0.15) }, "−");
  const zoomIn  = el("button", { class:"secondary", onclick: () => nudgeZoom(session, 0.15) }, "+");

  const tilt = el("input", { type:"range", min:TILT_MIN, max:TILT_MAX, value:v.tilt, step:1 });
  tilt.addEventListener("input", () => {
    session.view.tilt = clamp(+tilt.value, TILT_MIN, TILT_MAX);
    applyStageTransform(); touchSession(session); scheduleSave();
  });

  const reset = el("button", { class:"secondary", onclick: () => {
    session.view = { zoom:1, tilt:0, panX:0, panY:0 };
    tilt.value = 0; applyStageTransform(); touchSession(session); scheduleSave();
  } }, "視点リセット");

  const reselect = el("button", { class:"secondary", onclick: () => go("select") }, "カードを選び直す");
  const home = el("button", { class:"secondary", onclick: () => go("home") }, "ホームへ");

  return el("div", { class:"toolbar" },
    home, reselect,
    el("span", { class:"spacer" }),
    el("label", null, "ズーム", zoomOut, zoomIn),
    el("label", null, "傾き", tilt),
    reset
  );
}

function nudgeZoom(session, delta) {
  session.view.zoom = clamp(session.view.zoom + delta, ZOOM_MIN, ZOOM_MAX);
  applyStageTransform(); touchSession(session); scheduleSave();
}
```

- [ ] **Step 6: ブラウザで手動検証(ドラッグ以外)**

このタスクは `attachCardDrag` / `attachViewControls`(Task 6)未実装だと動かないため、一時的に空関数を置いてから検証する。

```js
function attachCardDrag(){}     // Task 6 で実装
function attachViewControls(){} // Task 6 で実装
```

- 5枚選んで確定 → 机の上に5枚が中央整列表示。カードごとに領域色の上辺。
- 傾きスライダーで机全体が奥に倒れる(3D俯瞰)。+/−でズーム。視点リセットで真上・等倍に戻る。
- リロード→開く→傾き・ズームが保持されている。「カードを選び直す」で選択画面へ、そこで1枚追加して確定 → 既存4枚は位置維持、追加1枚が中央付近に出る。

- [ ] **Step 7: Commit**

```bash
git add index.html
git commit -m "feat: ワークキャンバス(3D俯瞰・整列配置・ツールバー・選び直し整合)を追加"
```

---

### Task 6: カードのドラッグ移動と視点操作(ズーム/チルト/パン)

**Files:**
- Modify: `index.html`(レンダリング節。`attachCardDrag` / `attachViewControls` の空関数を本実装に置換)

**Interfaces:**
- Consumes: `stageEl`, `viewportEl`, `getCurrentSession`, `positionPiece`, `bringToFront`, `applyStageTransform`, `clamp`, `touchSession`, `scheduleSave`, `ZOOM_MIN/MAX`(Task 5)
- Produces:
  - `attachCardDrag(piece, session): void` — Pointer Events でカードを机平面上で移動。
  - `attachViewControls(session): void` — viewport 上でのホイールズーム・ピンチズーム・余白パンを担う。
  - `screenDeltaToStage(dx, dy, view): {x,y}` — スクリーン移動量を stage 論理座標の移動量へ逆変換。

- [ ] **Step 1: 座標逆変換ヘルパを書く**

ズームは全体倍率、チルトは縦方向のみ `cos` で圧縮されるため、論理移動量は横 `dx/zoom`、縦 `dy/(zoom*cos(tilt))`。perspective による遠近誤差は掴んだ点を基準に相対移動させることで実用上吸収する。

```js
function screenDeltaToStage(dx, dy, view) {
  const rad = view.tilt * Math.PI / 180;
  const cos = Math.max(Math.cos(rad), 0.2); // 0除算/過大補正の下限
  return { x: dx / view.zoom, y: dy / (view.zoom * cos) };
}
```

- [ ] **Step 2: `attachCardDrag` を実装(空関数置換)**

```js
function attachCardDrag(piece, session) {
  const id = piece.dataset.id;
  let startX = 0, startY = 0, origX = 0, origY = 0, dragging = false;

  piece.addEventListener("pointerdown", (e) => {
    e.stopPropagation(); // viewport のパンを起こさない
    dragging = true;
    piece.setPointerCapture(e.pointerId);
    piece.classList.add("dragging");
    startX = e.clientX; startY = e.clientY;
    const p = session.placements[id];
    origX = p.x; origY = p.y;
    bringToFront(session, id);
    piece.style.zIndex = session.placements[id].z;
  });

  piece.addEventListener("pointermove", (e) => {
    if (!dragging) return;
    const d = screenDeltaToStage(e.clientX - startX, e.clientY - startY, session.view);
    const p = session.placements[id];
    p.x = origX + d.x;
    p.y = origY + d.y;
    positionPiece(piece, p);
  });

  const end = (e) => {
    if (!dragging) return;
    dragging = false;
    piece.classList.remove("dragging");
    touchSession(session);
    scheduleSave();
  };
  piece.addEventListener("pointerup", end);
  piece.addEventListener("pointercancel", end);
}
```

- [ ] **Step 3: `attachViewControls` を実装(空関数置換)**

viewport 余白のドラッグでパン、ホイールでズーム、2本指でピンチズーム。

```js
function attachViewControls(session) {
  // ホイールズーム(カーソル基準は簡易に中心ズームで代替)
  viewportEl.addEventListener("wheel", (e) => {
    e.preventDefault();
    const delta = e.deltaY < 0 ? 0.1 : -0.1;
    session.view.zoom = clamp(session.view.zoom + delta, ZOOM_MIN, ZOOM_MAX);
    applyStageTransform(); touchSession(session); scheduleSave();
  }, { passive:false });

  // 余白ドラッグでパン
  let panning = false, sx = 0, sy = 0, opx = 0, opy = 0;
  viewportEl.addEventListener("pointerdown", (e) => {
    if (e.target !== viewportEl && e.target !== stageEl) return; // カード上は除外
    panning = true;
    viewportEl.setPointerCapture(e.pointerId);
    sx = e.clientX; sy = e.clientY;
    opx = session.view.panX; opy = session.view.panY;
  });
  viewportEl.addEventListener("pointermove", (e) => {
    if (!panning) return;
    session.view.panX = opx + (e.clientX - sx) / session.view.zoom;
    session.view.panY = opy + (e.clientY - sy) / session.view.zoom;
    applyStageTransform();
  });
  const endPan = () => { if (panning) { panning = false; touchSession(session); scheduleSave(); } };
  viewportEl.addEventListener("pointerup", endPan);
  viewportEl.addEventListener("pointercancel", endPan);

  attachPinch(session);
}
```

- [ ] **Step 4: ピンチズームを書く**

```js
function attachPinch(session) {
  const pts = new Map();
  let baseDist = 0, baseZoom = 1;
  viewportEl.addEventListener("pointerdown", (e) => {
    pts.set(e.pointerId, { x:e.clientX, y:e.clientY });
    if (pts.size === 2) {
      const [a, b] = [...pts.values()];
      baseDist = Math.hypot(a.x - b.x, a.y - b.y);
      baseZoom = session.view.zoom;
    }
  });
  viewportEl.addEventListener("pointermove", (e) => {
    if (!pts.has(e.pointerId)) return;
    pts.set(e.pointerId, { x:e.clientX, y:e.clientY });
    if (pts.size === 2 && baseDist > 0) {
      const [a, b] = [...pts.values()];
      const dist = Math.hypot(a.x - b.x, a.y - b.y);
      session.view.zoom = clamp(baseZoom * (dist / baseDist), ZOOM_MIN, ZOOM_MAX);
      applyStageTransform();
    }
  });
  const drop = (e) => {
    if (pts.has(e.pointerId)) { pts.delete(e.pointerId); baseDist = 0; touchSession(session); scheduleSave(); }
  };
  viewportEl.addEventListener("pointerup", drop);
  viewportEl.addEventListener("pointercancel", drop);
}
```

- [ ] **Step 5: ブラウザで手動検証(PC)**

- カードをドラッグ → ポインタに追従して移動、離すと止まる。ドラッグ中は浮き上がり最前面化。
- 傾き30°でもカードのドラッグが破綻せず(縦移動が机平面に沿う近似で)自然に動く。
- 机の余白をドラッグ → 全体がパンする。カード上のドラッグはパンを起こさない。
- ホイールでズーム。範囲 0.3〜3.0 で頭打ち。
- 移動/パン/ズーム後にリロード→開く → 位置・視点が復元される。

- [ ] **Step 6: ブラウザで手動検証(タッチ・任意)**

DevTools のデバイスエミュレーション or タブレットで、1本指カードドラッグ・1本指余白パン・2本指ピンチズームが動く。

- [ ] **Step 7: Commit**

```bash
git add index.html
git commit -m "feat: カードのドラッグ移動とズーム・チルト・パン・ピンチ操作を追加"
```

---

### Task 7: 仕上げ(タイトル編集・全体通し検証・README)

**Files:**
- Modify: `index.html`
- Create: `README.md`

**Interfaces:**
- Consumes: すべて
- Produces:
  - ホームのセッションタイトルを編集できる導線。
  - `README.md`。

- [ ] **Step 1: タイトル編集を追加**

`renderHome` のセッション項目のタイトル `el("div", null, s.title)` を、クリックで `prompt` 編集できる要素に差し替える。

```js
el("div", { style:"cursor:text", title:"クリックで名前を変更",
  onclick: () => {
    const t = prompt("ワークの名前", s.title);
    if (t != null && t.trim()) { s.title = t.trim(); touchSession(s); saveDB(); render(); }
  } }, s.title),
```

- [ ] **Step 2: READMEを書く**

```markdown
# スキーマ療法カード

ヤングの18の早期不適応スキーマをカードにして、選んで机の上に並べ、内省するためのセルフヘルプ用Webツールです。

## 使い方

`index.html` をブラウザで開くだけです。インストールもインターネット接続も不要です。

1. 気になるカードを選んで「確定」
2. 机の上でカードを自由に動かし、ズーム・傾き(俯瞰)で眺めながら整理する
3. 内容はブラウザ内(localStorage)に自動保存され、次回開くと続きから見られます

## 注意

- データはお使いのブラウザ内にのみ保存されます。別の端末・ブラウザには引き継がれません。
- プライベートブラウズでは保存されない場合があります。
- 本ツールは心理教育・自己理解の補助を目的としたもので、専門的な診断・治療の代替ではありません。
```

- [ ] **Step 3: 全体通し手動検証**

`localStorage.removeItem("schemaTherapyCard.v1")` してリロードし、設計書の検証方針6項目を順に確認する。
1. 初回起動 → 18枚が領域別表示
2. 複数選択 → 確定 → 選択カードのみ机に整列
3. ドラッグ/ズーム/チルト/パン/視点リセットが機能
4. リロード → ホームに前回セッション、開くと配置・視点復元
5. 選び直し → 保持/追加/削除ルールどおり
6. セッション削除・新規作成・タイトル編集が機能

- [ ] **Step 4: Commit**

```bash
git add index.html README.md
git commit -m "feat: タイトル編集とREADMEを追加し全体を仕上げ"
```

---

## Self-Review 結果

- **Spec coverage:** ホーム/選択/キャンバスの3画面(Task 3/4/5)、選択トグルと確定(Task 4)、3D俯瞰・ドラッグ・ズーム・チルト・パン・リセット(Task 5/6)、選び直しの位置保持ルール(Task 5 `reconcilePlacements`)、localStorage自動保存・デバウンス・破損時退避・使用不可時バナー(Task 2/3)、データモデル全フィールド(Task 2-5)、検証方針6項目(Task 7)、スコープ外項目は非実装。すべて対応済み。
- **Placeholder scan:** 各ステップに実コードを記載。Task 4 の `reconcilePlacements` 暫定版と Task 6 の空関数は「後続タスクで置換」と明示した意図的な段階実装で、プレースホルダではない。
- **Type consistency:** `SCHEMAS/DOMAINS/state/db/session.{selectedCardIds,placements,view}`、`el/go/render/getCurrentSession/schemaById/domainById/reconcilePlacements/applyStageTransform/positionPiece/bringToFront/screenDeltaToStage/scheduleSave/touchSession/clamp` の名称・シグネチャはタスク間で一致。`stageEl/viewportEl` の共有前提も一致。
