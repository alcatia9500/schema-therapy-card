# カードイラスト生成スクリプト
# Pollinations.ai(Flux)で img/{id}.jpg を再生成する。プロンプト・シードは採用版を記録。
# 使い方: pwsh tools/gen-images.ps1 [-Only abandonment,failure]
param([string[]]$Only)

$ErrorActionPreference = "Continue"
$outDir = Join-Path $PSScriptRoot "..\img"
New-Item -ItemType Directory -Force $outDir | Out-Null

# style1: 初回採用分 / style2: 再生成採用分(flat 2D 指定を強化)
$style1 = "Minimalist abstract conceptual illustration for a calm corporate mental-wellness card deck. Soft matte flat shapes, subtle paper grain texture, muted palette of warm cream, sage green, terracotta on off-white background. Generous negative space, quiet and dignified, Kinfolk magazine aesthetic, no people, no text, no letters, no typography, no watermark."
$style2 = "Minimalist abstract conceptual flat illustration for a calm corporate mental-wellness card deck. Soft matte flat shapes, subtle paper grain texture, muted palette of warm cream, sage green, terracotta on off-white background. Generous negative space, quiet and dignified, Kinfolk magazine aesthetic, flat 2D illustration not photograph, no people, no text, no letters, no typography, no watermark."

$cards = @(
  @{ id="abandonment"; seed=11; style=1; p="A small solitary smooth stone at the edge of vast empty cream space, a trail of fading dots leading toward a larger shape departing into the distance. Terracotta accent." }
  @{ id="mistrust"; seed=21; style=1; p="Two smooth stones facing each other, separated by a single thin tall pane of glass standing between them, guarded quiet distance. Terracotta accent." }
  @{ id="emotional-deprivation"; seed=32; style=2; p="A single empty ceramic bowl in dry warm light, soft rain falling only in the far distance behind it, none of the rain reaches the bowl, the bowl remains empty. Terracotta accent." }
  @{ id="defectiveness"; seed=42; style=2; p="Five identical smooth flat circles in a neat horizontal row, the last circle is pale and slipping downward out of the row, half faded. Terracotta accent." }
  @{ id="social-isolation"; seed=52; style=2; p="A tight group of seven small pebbles gathered close together on the left side, one single small pebble very far away near the lower right corner, enormous warm empty space between them. Terracotta accent." }
  @{ id="dependence"; seed=61; style=1; p="A small rounded stone leaning against a large steady boulder for support, unable to stand alone. Sage green accent." }
  @{ id="vulnerability"; seed=71; style=1; p="A fragile smooth egg resting below a large heavy stone slab suspended above it by a single thin thread, quiet frozen tension. Sage green accent." }
  @{ id="enmeshment"; seed=81; style=1; p="Two translucent overlapping circles almost completely merged into one, their boundaries dissolving into each other. Sage green accent." }
  @{ id="failure"; seed=93; style=2; p="A single arrow lying flat on the ground, having landed just short of a round archery target standing a little further away, the gap between them visible. Sage green accent." }
  @{ id="entitlement"; seed=103; style=2; p="One golden stone resting on a raised velvet cushion pedestal, while a row of identical plain grey stones sits directly on the bare floor below it. Muted mauve accent." }
  @{ id="insufficient-self-control"; seed=111; style=1; p="A tilted ceramic cup with small round beads spilling out, scattering and accelerating apart across the surface. Muted mauve accent." }
  @{ id="subjugation"; seed=121; style=1; p="A young green reed bent all the way horizontal under a heavy dark wooden beam pressing from above. Dusty blue accent." }
  @{ id="self-sacrifice"; seed=132; style=2; p="A tilted teapot actively pouring a visible stream of tea into a row of full cups, the teapot tipped far forward giving away everything it has. Dusty blue accent." }
  @{ id="approval-seeking"; seed=142; style=2; p="A potted plant dramatically bent sideways, its whole stem curving strongly toward a warm glowing circle of light on the far right, leaning far away from its own vertical axis. Dusty blue accent." }
  @{ id="negativity"; seed=151; style=1; p="Soft rolling hills gently rising, while one dark diagonal band of cloud descends across the pale sky above them. Olive green accent." }
  @{ id="emotional-inhibition"; seed=161; style=1; p="A lively wavy ribbon that becomes a perfectly straight flat line the moment it passes into a rigid rectangular frame. Olive green accent." }
  @{ id="unrelenting-standards"; seed=171; style=1; p="A tall thin ladder reaching toward a horizontal bar floating in the sky, the bar always slightly higher than the ladder's top. Olive green accent." }
  @{ id="punitiveness"; seed=181; style=1; p="A thin dark pendulum blade suspended perfectly still above a soft round cushion, restrained frozen tension, nothing broken. Olive green accent." }
)

foreach ($c in $cards) {
  if ($Only -and $Only -notcontains $c.id) { continue }
  $dest = Join-Path $outDir "$($c.id).jpg"
  $style = if ($c.style -eq 2) { $style2 } else { $style1 }
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
