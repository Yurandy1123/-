// ============================================================
// Ziyuukadai2026.pde  ★ メインファイル ★
//
// シーン番号一覧
//   0 : 戦闘メニュー（このファイル）
//   1 : 魔法陣       （KONOdemo_v1.pde）
//   2 : AR道具       （Tool.pde）
//   3 : 勝利         （このファイル）
//   4 : 敗北         （このファイル）
//   5 : 敵準備       （RX_magical_fight.pde）
//   6 : フリック防御 （RX_magical_fight.pde）
//   7 : トラッキング （RX_magical_fight.pde）
//   8 : 敵攻撃結果   （RX_magical_fight.pde）
// ============================================================

import processing.video.*;
import gab.opencv.*;
import jp.nyatla.nyar4psg.*;
import java.awt.Rectangle;

// =============================================
// 共有オブジェクト
// =============================================
Player player;
Enemy  enemy;
PFont  font;

// カメラ（魔法陣・AR道具で共有）
Capture   video;
OpenCV    opencv;
MultiMarker nya;

// ARモデル（Tool.pde で使用）
PShape[] itemModel = new PShape[3];

// =============================================
// 共有変数
// =============================================
int     scene      = 0;
String  message    = "";
boolean playerTurn = true;
int     timer      = 0;

// 防御ミニゲームの結果（RX_magical_fight.pde で使用）
boolean guardSuccess    = false;
int     enemyAttackType = 0;   // 0:フリック  1:トラッキング

// 魔法陣との連携（KONOdemo_v1.pde → このファイル）
int     magicDamage   = 0;
boolean magicFinished = false;

// 道具との連携（Tool.pde → このファイル）
boolean itemFinished = false;

// =============================================
// setup
// =============================================
void setup() {
  size(640, 480, P3D);
  hint(DISABLE_DEPTH_TEST);

  font = createFont("Meiryo", 24, true);
  textFont(font);
  textAlign(CENTER, CENTER);

  player = new Player(100, 50, 20);
  enemy  = new Enemy(120, 15);

  // ---- カメラ初期化 ----
  String[] cameras = Capture.list();
  if (cameras != null && cameras.length > 0) {
    // 複数カメラがある場合は cameras[0] を変更してください
    video  = new Capture(this, cameras[0]);
    video.start();
    opencv = new OpenCV(this, 640, 480);
  } else {
    println("カメラが見つかりません");
  }

  // ---- AR初期化（Tool.pde用）----
  // camera_para.dat と *.obj が data/ フォルダに必要です
  try {
    nya = new MultiMarker(this, width, height,
                          "camera_para.dat",
                          NyAR4PsgConfig.CONFIG_PSG);
    nya.addNyIdMarker(0, 40);
    nya.addNyIdMarker(1, 40);
    nya.addNyIdMarker(2, 40);
    itemModel[0] = loadShape("herb.obj");
    itemModel[1] = loadShape("bomb.obj");
    itemModel[2] = loadShape("seed.obj");
  } catch (Exception e) {
    println("AR初期化エラー: " + e.getMessage());
    println("camera_para.dat / *.obj を data/ フォルダに入れてください");
  }

  // ---- 魔法陣の初期化（KONOdemo_v1.pde の関数）----
  initMagic();
}

// =============================================
// draw
// =============================================
void draw() {
  // カメラフレーム更新（scene 1・2 で使用）
  if (video != null && video.available()) {
    video.read();
  }

  switch (scene) {
    case 0: battleScene();        break;
    case 1: magicDrawScene();     break;   // KONOdemo_v1.pde
    case 2: itemARScene();        break;   // Tool.pde
    case 3: winScene();           break;
    case 4: loseScene();          break;
    case 5: enemyPrepareScene();  break;   // RX_magical_fight.pde
    case 6: flickGuardScene();    break;   // RX_magical_fight.pde
    case 7: trackingGuardScene(); break;   // RX_magical_fight.pde
    case 8: enemyResultScene();   break;   // RX_magical_fight.pde
  }

  checkMagicResult();
  checkItemResult();
  checkGameEnd();
}

// =============================================
// 戦闘メニュー画面
// =============================================
void battleScene() {
  camera();
  background(240);

  fill(0);
  textSize(18);
  text("HP : " + player.hp, 70, 25);
  text("MP : " + player.mp, 70, 50);
  text("敵HP : " + enemy.hp, 570, 25);
  text(playerTurn ? "プレイヤーターン" : "敵ターン", width/2, 25);

  drawMonster();

  // ボタン
  fill(30);
  rect(30,  380, 130, 50);
  rect(180, 380, 130, 50);
  fill(255);
  textSize(18);
  text("たたかう", 95,  405);
  text("どうぐ",   245, 405);

  fill(0);
  textSize(16);
  text(message, width/2, 455);
}

void drawMonster() {
  fill(255, 0, 0);
  ellipse(width/2, 200, 100, 100);
  fill(0);
  textSize(20);
  text("敵", width/2, 200);
}

// =============================================
// 勝利・敗北
// =============================================
void winScene() {
  camera();
  background(100, 255, 100);
  fill(0);
  textSize(60);
  text("YOU WIN!", width/2, height/2);
}

void loseScene() {
  camera();
  background(255, 100, 100);
  fill(0);
  textSize(60);
  text("GAME OVER", width/2, height/2);
}

// =============================================
// 魔法陣の結果を受け取る
// =============================================
void checkMagicResult() {
  if (magicFinished) {
    enemy.hp   -= magicDamage;
    message     = "魔法成功！ " + magicDamage + " ダメージ";
    magicFinished = false;
    playerTurn  = false;
    startEnemyDefense();
  }
}

// 道具の結果を受け取る
void checkItemResult() {
  if (itemFinished) {
    itemFinished = false;
    playerTurn   = false;
    startEnemyDefense();
  }
}

// 防御ミニゲームへ移行
void startEnemyDefense() {
  enemyAttackType = int(random(2));
  guardSuccess    = false;
  timer           = 0;
  scene           = 5;
}

// 勝敗判定
void checkGameEnd() {
  if (scene == 3 || scene == 4) return;
  if (enemy.hp  <= 0) scene = 3;
  if (player.hp <= 0) scene = 4;
}

// =============================================
// アイテム使用関数（Tool.pde から呼ばれる）
// =============================================
void useHealItem() {
  player.hp = min(player.hp + 30, 100);
  message   = "HPを30回復！";
  itemFinished = true;
}

void usePowerItem() {
  player.attack += 10;
  message = "攻撃力アップ！";
  itemFinished = true;
}

// =============================================
// 入力処理
// =============================================
void mousePressed() {
  if (scene == 0 && playerTurn) {
    // 「たたかう」ボタン → 魔法陣へ
    if (mouseX > 30  && mouseX < 160 && mouseY > 380 && mouseY < 430) scene = 1;
    // 「どうぐ」ボタン  → AR道具へ
    if (mouseX > 180 && mouseX < 310 && mouseY > 380 && mouseY < 430) scene = 2;
  } else if (scene == 1) {
    magicMousePressed();    // KONOdemo_v1.pde
  } else if (scene == 6) {
    flickMousePressed();    // RX_magical_fight.pde
  }
}

void keyPressed() {
  // ESCキーでアプリが終了しないようにする
  if (keyCode == ESC) {
    key = 0;
    if (scene == 1 || scene == 2) {
      scene = 0;  // 戦闘画面へ戻る
    }
    return;
  }

  if (scene == 1) {
    magicKeyPressed();   // KONOdemo_v1.pde
  }
}

// =============================================
// Player / Enemy クラス
// =============================================
class Player {
  int hp, mp, attack;
  Player(int hp, int mp, int attack) {
    this.hp     = hp;
    this.mp     = mp;
    this.attack = attack;
  }
}

class Enemy {
  int hp, attack;
  Enemy(int hp, int attack) {
    this.hp     = hp;
    this.attack = attack;
  }
}
