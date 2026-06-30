// ============================================================
// KONOdemo_v1.pde  ★ 魔法陣担当 ★
//
// このファイルが担当するシーン
//   scene == 1 : 魔法陣画面
//
// メインとの連携方法
//   評価完了時に  magicDamage = ダメージ値;
//                magicFinished = true;
//   を設定すると、Ziyuukadai2026.pde が結果を受け取ります。
// ============================================================

// ---- 魔法陣専用変数 ----
color trackColor;
float threshold  = 25;
float smoothedX  = 0;
float smoothedY  = 0;
float easing     = 0.15;

ArrayList<PVector> currentStroke;    // 描いている軌跡
ArrayList<PVector> recognizedShape;  // エフェクト用の認識図形
boolean isDrawing  = false;
String  resultText = "魔法色をクリックで選択 / スペース:描画 / Enter:発動";
int     elementColor;

// =============================================
// 初期化（Ziyuukadai2026 の setup() から呼ばれる）
// =============================================
void initMagic() {
  currentStroke   = new ArrayList<PVector>();
  recognizedShape = new ArrayList<PVector>();
  trackColor   = color(255, 0, 0);
  elementColor = color(255);
}

// =============================================
// 魔法陣画面の描画（scene == 1 のとき呼ばれる）
// =============================================
void magicDrawScene() {
  camera();
  hint(DISABLE_DEPTH_TEST);

  if (video == null) {
    background(30);
    fill(255);
    textSize(24);
    text("カメラが見つかりません", width/2, height/2);
    textSize(16);
    text("Escキーで戻る", width/2, height/2 + 50);
    return;
  }

  video.loadPixels();

  // カメラ映像をウィンドウ全体に表示
  image(video, 0, 0, width, height);

  // ---- 1. 色トラッキング & 手ブレ補正 ----
  float scaleX = (float)width  / video.width;
  float scaleY = (float)height / video.height;
  float sumX = 0, sumY = 0;
  int   count = 0;

  for (int x = 0; x < video.width; x += 2) {
    for (int y = 0; y < video.height; y += 2) {
      int   loc = x + y * video.width;
      color c   = video.pixels[loc];
      float d   = dist(red(c), green(c), blue(c),
                       red(trackColor), green(trackColor), blue(trackColor));
      if (d < threshold) {
        sumX += x * scaleX;
        sumY += y * scaleY;
        count++;
      }
    }
  }

  if (count > 5) {
    smoothedX = lerp(smoothedX, sumX / count, easing);
    smoothedY = lerp(smoothedY, sumY / count, easing);

    fill(trackColor);
    strokeWeight(4.0);
    stroke(255);
    ellipse(smoothedX, smoothedY, 20, 20);
    noStroke();

    if (isDrawing) {
      int last = currentStroke.size() - 1;
      boolean far = (last < 0) ||
                    dist(smoothedX, smoothedY,
                         currentStroke.get(last).x,
                         currentStroke.get(last).y) > 5;
      if (far) currentStroke.add(new PVector(smoothedX, smoothedY));
    }
  }

  // ---- 2. 描いた軌跡を表示 ----
  if (currentStroke.size() > 0) {
    stroke(elementColor);
    strokeWeight(6);
    noFill();
    beginShape();
    for (PVector p : currentStroke) vertex(p.x, p.y);
    endShape();
  }

  // ---- 3. 認識図形エフェクト ----
  if (recognizedShape.size() > 0) {
    stroke(elementColor);
    strokeWeight(8);
    fill(elementColor, 100);
    beginShape();
    for (PVector p : recognizedShape) vertex(p.x, p.y);
    endShape(CLOSE);
  }

  // ---- 4. UI ----
  fill(0, 160);
  noStroke();
  rect(0, 0, width, 55);
  fill(255);
  textSize(18);
  textAlign(LEFT, CENTER);
  text(resultText, 10, 27);
  textAlign(RIGHT, CENTER);
  text("Cキー: クリア  |  Escキー: 戻る", width - 10, 27);
  textAlign(CENTER, CENTER);
}

// =============================================
// マウス処理（Ziyuukadai2026 の mousePressed から呼ばれる）
// =============================================
void magicMousePressed() {
  if (video == null) return;
  int vx  = int(mouseX * (float)video.width  / width);
  int vy  = int(mouseY * (float)video.height / height);
  int loc = vx + vy * video.width;
  if (loc >= 0 && loc < video.pixels.length) {
    trackColor = video.pixels[loc];
    smoothedX  = mouseX;
    smoothedY  = mouseY;
  }
}

// =============================================
// キー処理（Ziyuukadai2026 の keyPressed から呼ばれる）
// =============================================
void magicKeyPressed() {
  if (key == ' ') {
    isDrawing = true;
  } else if (key == ENTER || key == RETURN) {
    evaluateMagicCircle();
  } else if (key == 'c' || key == 'C') {
    currentStroke.clear();
    recognizedShape.clear();
    resultText   = "待機中...";
    elementColor = color(255);
  }
}

void keyReleased() {
  if (key == ' ') isDrawing = false;
}

// =============================================
// 魔法陣を評価してダメージを計算
// =============================================
void evaluateMagicCircle() {
  if (currentStroke.size() < 10) {
    resultText = "魔力が足りません（線が短すぎます）";
    return;
  }

  // 裏画面に描いた線をレンダリング
  int cvW = (video != null) ? video.width  : 640;
  int cvH = (video != null) ? video.height : 480;
  PGraphics pg = createGraphics(cvW, cvH);
  pg.beginDraw();
  pg.background(0);
  pg.noFill();
  pg.stroke(255);
  pg.strokeWeight(15);
  pg.beginShape();
  for (PVector p : currentStroke) {
    pg.vertex(p.x * (float)cvW / width,
              p.y * (float)cvH / height);
  }
  pg.endShape();
  pg.endDraw();

  // OpenCV で輪郭検出
  opencv.loadImage(pg.get());
  opencv.gray();
  opencv.threshold(127);

  ArrayList<Contour> contours = opencv.findContours();
  int damage = 0;

  if (contours.size() > 0) {
    // 最大輪郭を探す
    Contour biggest = contours.get(0);
    float   maxArea = biggest.area();
    for (Contour c : contours) {
      if (c.area() > maxArea) { maxArea = c.area(); biggest = c; }
    }

    Contour hull      = biggest.getConvexHull();
    float   shapeW    = hull.getBoundingBox().width;
    hull.setPolygonApproximationFactor(shapeW * 0.08);
    Contour approx    = hull.getPolygonApproximation();
    int     vertices  = approx.getPoints().size();
    damage            = int(hull.area() / 200);

    recognizedShape.clear();
    for (PVector p : approx.getPoints()) recognizedShape.add(p);

    if (vertices == 3) {
      resultText   = "【炎属性】ファイア！ ダメージ:" + damage;
      elementColor = color(255, 50, 50);
    } else if (vertices == 4) {
      resultText   = "【土属性】アース！ ダメージ:" + damage;
      elementColor = color(200, 150, 50);
    } else if (vertices >= 5) {
      resultText   = "【水属性】ウォーター！ ダメージ:" + damage;
      elementColor = color(50, 150, 255);
    } else {
      damage       = max(1, damage / 2);
      resultText   = "【無属性】魔力暴走！ ダメージ:" + damage;
      elementColor = color(200, 200, 200);
    }
  } else {
    damage       = max(1, currentStroke.size() / 5);
    resultText   = "【無属性】魔法不発！ ダメージ:" + damage;
    elementColor = color(150, 150, 150);
    recognizedShape.clear();
  }

  // ---- メインへ結果を渡す ----
  magicDamage   = damage;
  magicFinished = true;   // Ziyuukadai2026 の checkMagicResult() が受け取る

  currentStroke.clear();
  scene = 0;              // 戦闘画面へ戻る
}
