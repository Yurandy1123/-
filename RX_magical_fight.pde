// ============================================================
// RX_magical_fight.pde  ★ 防御ミニゲーム担当 ★
//
// このファイルが担当するシーン
//   scene == 5 : 敵準備（フリックかトラッキングかを告知）
//   scene == 6 : フリック防御
//   scene == 7 : トラッキング防御
//   scene == 8 : 敵攻撃結果（ダメージ演出 → scene 0 へ戻る）
//
// 共有変数（Ziyuukadai2026.pde で宣言済み）
//   guardSuccess    : 防御成功フラグ
//   enemyAttackType : 0=フリック  1=トラッキング
//   timer           : 汎用タイマー
//   player.hp       : プレイヤーHP
//   enemy.attack    : 敵の攻撃力
// ============================================================

// ---- フリック防御用変数 ----
float flickX, flickY;
float flickR     = 30;
int   flickCount = 0;
int   flickNeed  = 5;
int   flickTimer = 180;

// ---- トラッキング防御用変数 ----
float trackBallX, trackBallY;   // trackX/trackY は KONOdemo と名前が被るため trackBall～ に変更
float trackBallVX, trackBallVY;
float trackBallR = 35;
int   trackTimer = 180;
int   trackScore = 0;
int   trackNeed  = 90;

// =============================================
// scene 5 : 敵準備画面
// =============================================
void enemyPrepareScene() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  background(30);
  timer++;

  fill(255);
  textSize(32);
  text("敵の攻撃が来る！", width/2, height/2 - 60);
  textSize(24);

  if (enemyAttackType == 0) {
    text("フリック防御：球を素早くクリック！", width/2, height/2);
  } else {
    text("トラッキング防御：球をマウスで追え！", width/2, height/2);
  }

  if (timer > 90) {
    timer = 0;
    if (enemyAttackType == 0) startFlickGuard();
    else                       startTrackingGuard();
  }
}

// =============================================
// scene 6 : フリック防御
// =============================================
void startFlickGuard() {
  flickCount = 0;
  flickTimer = 180;
  spawnFlickTarget();
  scene = 6;
}

void flickGuardScene() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  background(20, 10, 10);
  flickTimer--;

  fill(255);
  textSize(26);
  text("フリック防御！", width/2, 45);
  textSize(20);
  text("クリック数 : " + flickCount + " / " + flickNeed, width/2, 85);
  text("残り時間 : " + flickTimer, width/2, 115);

  drawCrosshair();

  noStroke();
  fill(255, 80, 80);
  ellipse(flickX, flickY, flickR * 2, flickR * 2);
  fill(255);
  ellipse(flickX - 8, flickY - 8, flickR / 2, flickR / 2);

  if (flickTimer <= 0) {
    guardSuccess = (flickCount >= flickNeed);
    timer = 0;
    scene = 8;
  }
}

void spawnFlickTarget() {
  flickX = random(100, width  - 100);
  flickY = random(150, height - 100);
}

// フリックのマウス処理（Ziyuukadai2026 の mousePressed から呼ばれる）
void flickMousePressed() {
  float d = dist(mouseX, mouseY, flickX, flickY);
  if (d <= flickR) {
    flickCount++;
    spawnFlickTarget();
    if (flickCount >= flickNeed) {
      guardSuccess = true;
      timer = 0;
      scene = 8;
    }
  }
}

// =============================================
// scene 7 : トラッキング防御
// =============================================
void startTrackingGuard() {
  trackBallX  = width  / 2;
  trackBallY  = height / 2;
  trackBallVX = random(3, 6);
  trackBallVY = random(3, 6);
  trackTimer  = 180;
  trackScore  = 0;
  scene       = 7;
}

void trackingGuardScene() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  background(0, 20, 20);
  trackTimer--;

  trackBallX += trackBallVX;
  trackBallY += trackBallVY;
  if (trackBallX < trackBallR || trackBallX > width  - trackBallR) trackBallVX *= -1;
  if (trackBallY < 140        || trackBallY > height - trackBallR) trackBallVY *= -1;

  float d = dist(mouseX, mouseY, trackBallX, trackBallY);
  if (d < trackBallR) trackScore++;

  fill(255);
  textSize(26);
  text("トラッキング防御！", width/2, 45);
  textSize(20);
  text("球をマウスで追い続けろ", width/2, 85);
  text("防御ゲージ : " + trackScore + " / " + trackNeed, width/2, 115);
  text("残り時間 : " + trackTimer, width/2, 145);

  noStroke();
  fill(d < trackBallR ? color(0, 255, 150) : color(255, 80, 80));
  ellipse(trackBallX, trackBallY, trackBallR * 2, trackBallR * 2);

  drawCrosshair();

  if (trackTimer <= 0) {
    guardSuccess = (trackScore >= trackNeed);
    timer = 0;
    scene = 8;
  }
}

// =============================================
// scene 8 : 敵攻撃結果
// =============================================
void enemyResultScene() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  background(30, 0, 0);
  timer++;

  fill(255);
  textSize(32);
  text("敵の攻撃！", width/2, height/2 - 130);

  int damage;
  if (guardSuccess) {
    damage = max(1, enemy.attack / 3);
    textSize(24);
    text("防御成功！ ダメージ " + damage, width/2, height/2 - 70);
  } else {
    damage = enemy.attack;
    textSize(24);
    text("防御失敗！ ダメージ " + damage, width/2, height/2 - 70);
  }

  // 攻撃エフェクト（円が広がる）
  fill(180, 0, 255, 180);
  noStroke();
  float s = min(timer * 8, 250);
  ellipse(width / 4, height / 2 + 50, s, s);

  if (timer > 40) {
    player.hp -= damage;
    message    = message + "  /  敵の攻撃 " + damage + "ダメージ";
    timer      = 0;
    guardSuccess = false;
    scene      = 0;   // 戦闘メニューへ戻る
  }
}

// =============================================
// クロスヘア描画（共通）
// =============================================
void drawCrosshair() {
  stroke(255);
  strokeWeight(2);
  line(mouseX - 15, mouseY,      mouseX + 15, mouseY);
  line(mouseX,      mouseY - 15, mouseX,      mouseY + 15);
  noStroke();
}
