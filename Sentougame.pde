Player player;
Enemy enemy;

PFont font;

// 画面
// 0:戦闘
// 1:魔法陣
// 2:道具
// 3:勝利
// 4:敗北
int scene = 0;

String message = "";

// ターン管理
boolean playerTurn = true;

// 魔法陣担当から受け取る値
int magicDamage = 0;
boolean magicFinished = false;

// 道具担当から受け取る値
boolean itemFinished = false;

void setup() {

  size(1000, 700);

  // 日本語文字化け対策
  font = createFont("Meiryo", 24, true);
  textFont(font);

  player = new Player(100, 50, 20);
  enemy = new Enemy(100, 15);

  textAlign(CENTER, CENTER);
}

void draw() {

  background(240);

  switch(scene) {

  case 0:
    battleScene();
    break;

  case 1:
    magicScene();
    break;

  case 2:
    itemScene();
    break;

  case 3:
    winScene();
    break;

  case 4:
    loseScene();
    break;
  }

  checkMagicResult();
  checkItemResult();
  checkGameEnd();
}

//====================
// プレイヤー
//====================
class Player {

  int hp;
  int mp;
  int attack;

  Player(int hp, int mp, int attack) {
    this.hp = hp;
    this.mp = mp;
    this.attack = attack;
  }
}

//====================
// 敵
//====================
class Enemy {

  int hp;
  int attack;

  Enemy(int hp, int attack) {
    this.hp = hp;
    this.attack = attack;
  }
}

//====================
// 戦闘画面
//====================
void battleScene() {

  fill(0);
  textSize(24);

  text("HP : " + player.hp, 100, 80);
  text("MP : " + player.mp, 100, 120);

  text("敵HP : " + enemy.hp, 850, 80);

  if(playerTurn) {
    text("プレイヤーターン", 500, 50);
  } else {
    text("敵ターン", 500, 50);
  }

  drawMonster();

  fill(0);
  rect(50, 500, 180, 70);
  rect(250, 500, 180, 70);

  fill(255);
  text("たたかう", 140, 535);
  text("どうぐ", 340, 535);

  fill(0);
  text(message, 500, 620);
}

//====================
// モンスター表示
//====================
void drawMonster() {

  fill(255, 0, 0);
  ellipse(500, 250, 150, 150);

  fill(0);
  text("敵", 500, 250);
}

//====================
// 魔法陣画面
//====================
void magicScene() {

  background(30);

  fill(255);
  text("魔法陣担当の画面", width/2, height/2);
}

//====================
// 道具画面
//====================
void itemScene() {

  background(50);

  fill(255);
  text("道具担当の画面", width/2, height/2);
}

//====================
// ボタン処理
//====================
void mousePressed() {

  if(scene == 0 && playerTurn) {

    // たたかう
    if(mouseX > 50 &&
       mouseX < 230 &&
       mouseY > 500 &&
       mouseY < 570) {

      scene = 1;
    }

    // どうぐ
    if(mouseX > 250 &&
       mouseX < 430 &&
       mouseY > 500 &&
       mouseY < 570) {

      scene = 2;
    }
  }
}

//====================
// 魔法陣結果
//====================
void checkMagicResult() {

  if(magicFinished) {

    enemy.hp -= magicDamage;

    message =
      "魔法成功！ " +
      magicDamage +
      "ダメージ";

    magicFinished = false;

    playerTurn = false;

    enemyAttack();

    scene = 0;
  }
}

//====================
// 道具結果
//====================
void checkItemResult() {

  if(itemFinished) {

    itemFinished = false;

    playerTurn = false;

    enemyAttack();

    scene = 0;
  }
}

//====================
// 回復アイテム
//====================
void useHealItem() {

  player.hp += 30;

  if(player.hp > 100) {
    player.hp = 100;
  }

  message = "HPを30回復";

  itemFinished = true;
}

//====================
// 攻撃力アップ
//====================
void usePowerItem() {

  player.attack += 10;

  message = "攻撃力アップ";

  itemFinished = true;
}

//====================
// 敵攻撃
//====================
void enemyAttack() {

  if(enemy.hp > 0) {

    player.hp -= enemy.attack;

    message +=
      " 敵の攻撃 " +
      enemy.attack +
      "ダメージ";

    playerTurn = true;
  }
}

//====================
// 勝敗判定
//====================
void checkGameEnd() {

  if(enemy.hp <= 0) {
    scene = 3;
  }

  if(player.hp <= 0) {
    scene = 4;
  }
}

//====================
// 勝利
//====================
void winScene() {

  background(100, 255, 100);

  fill(0);
  textSize(60);

  text("YOU WIN!", width/2, height/2);
}

//====================
// 敗北
//====================
void loseScene() {

  background(255, 100, 100);

  fill(0);
  textSize(60);

  text("GAME OVER", width/2, height/2);
}
