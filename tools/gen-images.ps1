# カードイラスト生成スクリプト
# Pollinations.ai(Flux)で img/{id}.jpg を再生成する。プロンプト・シードは採用版(フラット・エディトリアル様式)を記録。
# 使い方: pwsh tools/gen-images.ps1 [-Only abandonment,failure]
param([string[]]$Only)

$ErrorActionPreference = "Continue"
$outDir = Join-Path $PSScriptRoot "..\img"
New-Item -ItemType Directory -Force $outDir | Out-Null

$style = "Minimal flat editorial illustration for a corporate wellness magazine, faceless human figures drawn with simple rounded shapes, muted palette of slate blue, sage green, terracotta on warm cream paper background, subtle grain, soft shadows, calm dignified mood, generous negative space, no text, no letters, no watermark."

$cards = @(
  @{ id="abandonment"; seed=307; p="A small seated human figure alone on the left, watching a larger figure walking away toward the far right edge, a long empty space and a fading dotted path stretching between them." }
  @{ id="mistrust"; seed=311; p="A faceless human figure standing with arms crossed behind a tall transparent glass wall, another figure gently extending a hand from the other side, cautious guarded distance between them. Terracotta accent." }
  @{ id="emotional-deprivation"; seed=312; p="A faceless figure sitting alone at one end of a very long empty dining table with an empty plate, a warm patch of light falling far away at the other end. Terracotta accent." }
  @{ id="defectiveness"; seed=413; p="A line of faceless figures standing in warm bright light, and apart from them one figure standing inside a soft grey shadow area, head bowed, shoulders drawn in. Terracotta accent." }
  @{ id="social-isolation"; seed=414; p="One faceless figure standing alone in the large empty foreground, far behind it a tight circle of figures gathered together facing each other. Terracotta accent." }
  @{ id="dependence"; seed=521; p="A small faceless figure standing on the open palm of a giant gentle hand that carries it forward through the air. Sage green accent." }
  @{ id="vulnerability"; seed=322; p="A faceless figure gripping an umbrella under a completely clear bright sky, anxiously watching one tiny dark cloud far away on the horizon. Sage green accent." }
  @{ id="enmeshment"; seed=323; p="Two overlapping translucent faceless human silhouettes merged into each other sharing a single shadow, their outlines dissolving together. Sage green accent." }
  @{ id="failure"; seed=424; p="A single faceless figure sitting slumped on the lowest step of a long ascending staircase, looking up toward the top far above. Sage green accent." }
  @{ id="entitlement"; seed=331; p="A confident faceless figure walking straight past a long patient queue of waiting figures, heading directly to the front. Muted mauve accent." }
  @{ id="insufficient-self-control"; seed=332; p="A faceless figure leaving a straight marked path to chase several colorful balloons drifting away in different directions. Muted mauve accent." }
  @{ id="subjugation"; seed=307; p="A human figure kneeling low and bowing deeply beneath a large heavy geometric slab hovering just above, pressing the figure downward." }
  @{ id="self-sacrifice"; seed=641; p="A faceless figure walking bent forward under the weight of carrying a much larger figure on its back, patiently and quietly. Dusty blue accent." }
  @{ id="approval-seeking"; seed=342; p="A faceless figure on a small stage bowing deeply toward rows of clapping hands, its whole posture bent toward the audience. Dusty blue accent." }
  @{ id="negativity"; seed=351; p="A faceless figure walking with one small personal rain cloud directly above its head, while the rest of the wide sky is clear and bright. Olive green accent." }
  @{ id="emotional-inhibition"; seed=552; p="A faceless figure calmly pressing down the lid of a large box, colorful ribbons overflowing and escaping from under the lid. Olive green accent." }
  @{ id="unrelenting-standards"; seed=307; p="A tiny human figure climbing an impossibly tall thin ladder that extends beyond the top edge of the frame, the top of the ladder never visible." }
  @{ id="punitiveness"; seed=453; p="A small faceless figure standing below a giant stern index finger pointing down at it from the sky, quiet frozen tension, nothing touching. Olive green accent." }
)

foreach ($c in $cards) {
  if ($Only -and $Only -notcontains $c.id) { continue }
  $dest = Join-Path $outDir "$($c.id).jpg"
  $prompt = "$($c.p) $style"
  $url = "https://image.pollinations.ai/prompt/$([uri]::EscapeDataString($prompt))?width=832&height=512&seed=$($c.seed)&nologo=true&model=flux"
  $ok = $false
  for ($try = 1; $try -le 3 -and -not $ok; $try++) {
    try {
      Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 180
      if ((Get-Item $dest).Length -gt 5000) { $ok = $true }
    } catch {
      Start-Sleep -Seconds (5 * $try)
    }
  }
  Write-Output "$($c.id): $(if ($ok) { 'OK ' + (Get-Item $dest).Length } else { 'FAILED' })"
}
