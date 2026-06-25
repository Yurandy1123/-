PFont jpFont;

int scene = 0;
// 0: タイトル
// 1: コマンド選択
// 2: 自分の魔法攻撃
// 3: 防御方法表示
// 4: フリック防御
// 5: トラッキング防御
// 6: 敵攻撃結果
// 7: 勝利
// 8: 敗北

int playerHP = 100;
int enemyHP = 100;
int command = 0;
int timer = 0;

String[] commands = {"戦う", "防御", "逃げる"};

boolean guardSuccess = false;
int enemyAttackType = 0; 
// 0: フリック
// 1: トラッキング

// フリック防御用
float flickX, flickY;
float flickR = 30;
int flickCount = 0;
int flickNeed = 5;
int flickTimer = 180;

// トラッキング防御用
float trackX, trackY;
float trackVX, trackVY;
float trackR = 35;
int trackTimer = 180;
int trackScore = 0;
int trackNeed = 90;

void setup() {
  size(800, 600);

  jpFont = createFont("Yu Gothic UI", 32);
  textFont(jpFont);
  textAlign(CENTER, CENTER);
}

void draw() {
  background(30);

  if (scene == 0) titleScene();
  else if (scene == 1) commandScene();
  else if (scene == 2) playerAttackScene();
  else if (scene == 3) enemyPrepareScene();
  else if (scene == 4) flickGuardScene();
  else if (scene == 5) trackingGuardScene();
  else if (scene == 6) enemyResultScene();
  else if (scene == 7) resultScene("勝利！");
  else if (scene == 8) resultScene("敗北...");
}

void titleScene() {
  fill(255);
  textSize(48);
  text("魔法バトル", width/2, 180);

  textSize(24);
  text("ENTERキーで開始", width/2, 320);
}

void commandScene() {
  fill(255);
  textSize(24);
  text("プレイヤーHP : " + playerHP, 200, 70);
  text("敵HP : " + enemyHP, 600, 70);

  textSize(36);

  for (int i = 0; i < commands.length; i++) {
    if (i == command) {
      fill(255, 220, 0);
      text("▶ " + commands[i], width/2, 220 + i * 70);
    } else {
      fill(255);
      text(commands[i], width/2, 220 + i * 70);
    }
  }

  textSize(18);
  fill(200);
  text("↑↓で選択　ENTERで決定", width/2, 520);
}

void playerAttackScene() {
  timer++;

  background(10, 0, 30);

  fill(255);
  textSize(32);
  text("魔法攻撃！", width/2, 100);

  fill(255, 120, 0);
  float s = timer * 10;
  ellipse(600, 300, s, s);

  if (timer > 40) {
    enemyHP -= 25;
    timer = 0;

    if (enemyHP <= 0) {
      enemyHP = 0;
      scene = 7;
    } else {
      startEnemyPrepare();
    }
  }
}

void startEnemyPrepare() {
  enemyAttackType = int(random(2));
  guardSuccess = false;
  timer = 0;
  scene = 3;
}

void enemyPrepareScene() {
  timer++;

  fill(255);
  textSize(32);
  text("敵の攻撃が来る！", width/2, 230);

  textSize(24);

  if (enemyAttackType == 0) {
    text("フリック防御：球を素早くクリック！", width/2, 300);
  } else {
    text("トラッキング防御：球を追い続けろ！", width/2, 300);
  }

  if (timer > 60) {
    if (enemyAttackType == 0) {
      startFlickGuard();
    } else {
      startTrackingGuard();
    }
  }
}

void startFlickGuard() {
  flickCount = 0;
  flickTimer = 180;
  spawnFlickTarget();
  scene = 4;
}

void flickGuardScene() {
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
    if (flickCount >= flickNeed) {
      guardSuccess = true;
    } else {
      guardSuccess = false;
    }

    timer = 0;
    scene = 6;
  }
}

void spawnFlickTarget() {
  flickX = random(100, width - 100);
  flickY = random(150, height - 100);
}

void startTrackingGuard() {
  trackX = width/2;
  trackY = height/2;
  trackVX = random(3, 6);
  trackVY = random(3, 6);
  trackTimer = 180;
  trackScore = 0;
  scene = 5;
}

void trackingGuardScene() {
  background(0, 20, 20);

  trackTimer--;

  trackX += trackVX;
  trackY += trackVY;

  if (trackX < trackR || trackX > width - trackR) {
    trackVX *= -1;
  }

  if (trackY < 140 || trackY > height - trackR) {
    trackVY *= -1;
  }

  float d = dist(mouseX, mouseY, trackX, trackY);

  if (d < trackR) {
    trackScore++;
  }

  fill(255);
  textSize(26);
  text("トラッキング防御！", width/2, 45);

  textSize(20);
  text("球をマウスで追い続けろ", width/2, 85);
  text("防御ゲージ : " + trackScore + " / " + trackNeed, width/2, 115);
  text("残り時間 : " + trackTimer, width/2, 145);

  noStroke();

  if (d < trackR) {
    fill(0, 255, 150);
  } else {
    fill(255, 80, 80);
  }

  ellipse(trackX, trackY, trackR * 2, trackR * 2);

  drawCrosshair();

  if (trackTimer <= 0) {
    if (trackScore >= trackNeed) {
      guardSuccess = true;
    } else {
      guardSuccess = false;
    }

    timer = 0;
    scene = 6;
  }
}

void enemyResultScene() {
  timer++;

  background(30, 0, 0);

  fill(255);
  textSize(32);
  text("敵の攻撃！", width/2, 100);

  int damage;

  if (guardSuccess) {
    damage = 5;
    textSize(24);
    text("防御成功！ ダメージ軽減", width/2, 160);
  } else {
    damage = 20;
    textSize(24);
    text("防御失敗！", width/2, 160);
  }

  fill(180, 0, 255);
  float s = timer * 8;
  ellipse(200, 300, s, s);

  if (timer > 40) {
    playerHP -= damage;
    timer = 0;
    guardSuccess = false;

    if (playerHP <= 0) {
      playerHP = 0;
      scene = 8;
    } else {
      scene = 1;
    }
  }
}

void resultScene(String message) {
  fill(255);
  textSize(60);
  text(message, width/2, 250);

  textSize(24);
  text("ENTERキーでタイトルへ戻る", width/2, 350);
}

void drawCrosshair() {
  stroke(255);
  strokeWeight(2);
  line(mouseX - 15, mouseY, mouseX + 15, mouseY);
  line(mouseX, mouseY - 15, mouseX, mouseY + 15);
}

void keyPressed() {
  if (scene == 0) {
    if (keyCode == ENTER) {
      scene = 1;
    }
  }

  else if (scene == 1) {
    if (keyCode == UP) {
      command--;
      if (command < 0) command = commands.length - 1;
    }

    else if (keyCode == DOWN) {
      command++;
      if (command >= commands.length) command = 0;
    }

    else if (keyCode == ENTER) {
      if (command == 0) {
        timer = 0;
        scene = 2;
      } else if (command == 1) {
        playerHP += 10;
        if (playerHP > 100) playerHP = 100;
        startEnemyPrepare();
      } else if (command == 2) {
        scene = 0;
      }
    }
  }

  else if (scene == 7 || scene == 8) {
    if (keyCode == ENTER) {
      resetGame();
    }
  }
}

void mousePressed() {
  if (scene == 4) {
    float d = dist(mouseX, mouseY, flickX, flickY);

    if (d <= flickR) {
      flickCount++;
      spawnFlickTarget();

      if (flickCount >= flickNeed) {
        guardSuccess = true;
        timer = 0;
        scene = 6;
      }
    }
  }
}

void resetGame() {
  playerHP = 100;
  enemyHP = 100;
  command = 0;
  timer = 0;
  guardSuccess = false;
  scene = 0;
}
