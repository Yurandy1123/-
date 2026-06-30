// ============================================================
// Tool.pde  ★ AR道具担当 ★
//
// このファイルが担当するシーン
//   scene == 2 : AR道具画面
//
// 必要ファイル（スケッチの data/ フォルダに入れてください）
//   camera_para.dat  … ARカメラキャリブレーション
//   herb.obj         … マーカーID 0 のモデル（回復薬）
//   bomb.obj         … マーカーID 1 のモデル（爆弾）
//   seed.obj         … マーカーID 2 のモデル（パワーシード）
//
// メインとの連携方法
//   道具を使ったとき useHealItem() / itemFinished = true を呼ぶと
//   Ziyuukadai2026.pde が結果を受け取って防御シーンへ移ります。
// ============================================================

// ---- 道具専用変数 ----
float attackBuff  = 1.0;
int   lastUseFrame = -100;
int   cooldown    = 300;   // 約5秒（60fps × 5）

// =============================================
// scene 2 : AR道具画面（draw から呼ばれる）
// =============================================
void itemARScene() {

  // カメラ or AR が未初期化の場合はエラー表示
  if (video == null || nya == null) {
    camera();
    hint(DISABLE_DEPTH_TEST);
    background(40);
    fill(255);
    textSize(22);
    text("カメラまたはARライブラリが初期化されていません", width/2, height/2 - 30);
    textSize(16);
    text("data/ フォルダに camera_para.dat と *.obj を入れてください", width/2, height/2 + 10);
    text("Escキーで戦闘画面に戻る", width/2, height/2 + 50);
    return;
  }

  // ARマーカー検出
  nya.detect(video);

  // カメラ映像を背景に表示
  background(0);
  nya.drawBackground(video);

  // 3Dモデルをマーカー上に表示
  hint(ENABLE_DEPTH_TEST);
  for (int i = 0; i < 3; i++) {
    if (!nya.isExist(i)) continue;

    nya.beginTransform(i);
    pushMatrix();
      lights();
      translate(0, 0, 20);
      scale(0.3);
      rotateX(radians(90));
      rotateY(radians(180));
      rotateY(frameCount * 0.01);
      if (itemModel[i] != null) shape(itemModel[i]);
    popMatrix();
    nya.endTransform();

    // クールタイムが明けていたらアイテム使用
    useItemByMarker(i);
  }

  // ---- UIを2Dで重ねて表示 ----
  hint(DISABLE_DEPTH_TEST);
  camera();
  drawItemUI();
}

// =============================================
// アイテム使用（クールタイム管理）
// =============================================
void useItemByMarker(int id) {
  if (frameCount - lastUseFrame < cooldown) return;
  lastUseFrame = frameCount;

  if      (id == 0) useHerb();
  else if (id == 1) useBomb();
  else if (id == 2) usePowerSeed();
}

// ---- やくそう（回復）----
void useHerb() {
  useHealItem();   // Ziyuukadai2026.pde の関数（HP+30 & itemFinished=true）
  message = "やくそうで HP を30回復！";
}

// ---- ばくだん（敵にダメージ）----
void useBomb() {
  int damage = 20;
  enemy.hp = max(enemy.hp - damage, 0);
  message  = "ばくだんで " + damage + "ダメージ！";
  itemFinished = true;   // 戦闘続行フラグ
}

// ---- パワーシード（攻撃力アップ）----
void usePowerSeed() {
  if (attackBuff < 1.5) {   // 重複適用防止
    attackBuff     = 1.5;
    player.attack  = int(player.attack * 1.5);
  }
  message = "攻撃力が上がった！";
  itemFinished = true;
}

// =============================================
// 道具画面のUI表示
// =============================================
void drawItemUI() {
  // 下部に半透明バー
  fill(0, 160);
  noStroke();
  rect(0, height - 110, width, 110);

  fill(255);
  textSize(16);
  textAlign(LEFT, CENTER);
  text("Player HP : " + player.hp + " / 100",  20, height - 90);
  text("Enemy  HP : " + enemy.hp,               20, height - 68);
  text("攻撃バフ  : x" + nf(attackBuff, 1, 1), 20, height - 46);
  text(message,                                  20, height - 24);

  // 右側に操作説明
  textAlign(RIGHT, CENTER);
  textSize(14);
  text("マーカーを見せてアイテムを使う", width - 20, height - 68);
  text("Escキー : 戦闘画面へ戻る",       width - 20, height - 46);

  textAlign(CENTER, CENTER);
}
