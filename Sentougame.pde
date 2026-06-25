// プレイヤーと敵の情報
Player player;
Enemy enemy;

// 画面管理
// 0:戦闘
// 1:魔法陣
// 2:道具
// 3:勝利
// 4:敗北
int scene = 0;

// メッセージ表示
String message = "";

// ターン管理
boolean playerTurn = true;

void setup() {

  size(1000, 700);

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

  checkGameEnd();
}

// プレイヤークラス

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


// 敵クラス

class Enemy {

  int hp;
  int attack;

  Enemy(int hp, int attack) {

    this.hp = hp;
    this.attack = attack;
  }
}


// 戦闘画面

void battleScene() {

  fill(0);

  textSize(25);

  text("HP : " + player.hp, 100, 80);
  text("MP : " + player.mp, 100, 120);

  text("敵HP : " + enemy.hp, 850, 80);

  // ターン表示
  if(playerTurn) {
    text("プレイヤーのターン", 500, 50);
  }
  else {
    text("敵のターン", 500, 50);
  }

  // モンスター表示
  drawMonster();

  // たたかうボタン
  rect(50, 500, 180, 70);
  fill(255);
  text("たたかう", 140, 535);

  // どうぐボタン
  fill(0);
  rect(250, 500, 180, 70);
  fill(255);
  text("どうぐ", 340, 535);

  fill(0);
  text(message, 500, 620);
}


// 戦闘

void drawMonster() {
  
  fill(255, 0, 0);
  ellipse(500, 250, 150, 150);

  fill(0);
  text("敵", 500, 250);

}


// 魔法陣

void magicScene() {


}



// 道具

void itemScene() {

}


// マウス処理
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


// 攻撃成功

void attackEnemy() {

  if(playerTurn) {

    enemy.hp -= player.attack;

    message =
      "プレイヤーの攻撃！ "
      + player.attack
      + "ダメージ";

    playerTurn = false;

    enemyAttack();

    scene = 0;
  }
}


// 敵の攻撃

void enemyAttack() {

  if(enemy.hp > 0) {

    player.hp -= enemy.attack;

    message +=
      " 敵の反撃！ "
      + enemy.attack
      + "ダメージ";

    playerTurn = true;
  }
}



// 回復アイテム

void useHealItem() {

  if(playerTurn) {

    player.hp += 30;

    if(player.hp > 100) {
      player.hp = 100;
    }

    message = "HPを30回復した";

    playerTurn = false;

    enemyAttack();

    scene = 0;
  }
}



// 攻撃力アップアイテム

void usePowerItem() {

  if(playerTurn) {

    player.attack += 10;

    message = "攻撃力が10上がった";

    playerTurn = false;

    enemyAttack();

    scene = 0;
  }
}


// 勝敗判定

void checkGameEnd() {

  if(enemy.hp <= 0) {

    scene = 3;
  }

  if(player.hp <= 0) {

    scene = 4;
  }
}


// 勝利画面

void winScene() {

  background(100, 255, 100);

  fill(0);

  textSize(60);

  text("YOU WIN!", width/2, height/2);
}


// 敗北画面

void loseScene() {

  background(255, 100, 100);

  fill(0);

  textSize(60);

  text("GAME OVER", width/2, height/2);
}
