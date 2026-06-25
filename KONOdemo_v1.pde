import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;

Capture video;
OpenCV opencv;

// 編集できているかテスト

// パラメータ設定

// 色トラッキング・手ブレ補正
color trackColor;
float threshold = 25;      // 色の許容範囲
float smoothedX = 0;       // 補正後のX座標
float smoothedY = 0;       // 補正後のY座標
float easing = 0.15;       // 手ブレ補正の強さ（小さいほど滑らか）

// 魔方陣描画用
ArrayList<PVector> currentStroke;   // 描いている軌跡
ArrayList<PVector> recognizedShape; // 認識された魔法陣の形（エフェクト用）
boolean isDrawing = false;
String resultText = "魔法色をクリックで選択\nスペースキーで描画、エンターで発動";
int elementColor = color(255);

void setup() {
  size(640, 480);
  
  // 文字化け対策（Macの場合は "Hiragino Sans" 等に変更してください）
  PFont font = createFont("Meiryo", 24);
  textFont(font);
  
  // カメラとOpenCVの初期化
  video = new Capture(this, width, height);
  video.start();
  opencv = new OpenCV(this, width, height);
  
  // リストの初期化
  currentStroke = new ArrayList<PVector>();
  recognizedShape = new ArrayList<PVector>(); 
  trackColor = color(255, 0, 0); 
}

void draw() {
  if (video.available()) {
    video.read();
  }
  
  video.loadPixels();
  image(video, 0, 0);

  // ==========================================
  // 1. 重心トラッキング ＆ 手ブレ補正処理
  // ==========================================
  float sumX = 0;
  float sumY = 0;
  int count = 0;
  
  // 負荷軽減のため2ピクセル飛ばしで走査
  for (int x = 0; x < video.width; x += 2) {
    for (int y = 0; y < video.height; y += 2) {
      int loc = x + y * video.width;
      color currentColor = video.pixels[loc];
      float d = dist(red(currentColor), green(currentColor), blue(currentColor), 
                     red(trackColor), green(trackColor), blue(trackColor)); 
      
      if (d < threshold) {
        sumX += x; 
        sumY += y; 
        count++;
      }
    }
  }

  // 許容範囲の色が見つかった場合
  if (count > 5) { 
    // 目標座標へ滑らかに追従（Lerp）
    smoothedX = lerp(smoothedX, sumX / count, easing);
    smoothedY = lerp(smoothedY, sumY / count, easing);

    // カーソルの描画
    fill(trackColor);
    strokeWeight(4.0);
    stroke(255);
    ellipse(smoothedX, smoothedY, 20, 20);
    noStroke();
    
    // 描画中（スペースキー押下）なら軌跡を記録
    if (isDrawing) {
      if (currentStroke.size() == 0 || dist(smoothedX, smoothedY, currentStroke.get(currentStroke.size()-1).x, currentStroke.get(currentStroke.size()-1).y) > 5) {
        currentStroke.add(new PVector(smoothedX, smoothedY));
      }
    }
  }

  // ==========================================
  // 2. 描いた魔方陣（軌跡）を画面に表示
  // ==========================================
  if (currentStroke.size() > 0) {
    stroke(elementColor);
    strokeWeight(6);
    noFill();
    beginShape();
    for (PVector p : currentStroke) {
      vertex(p.x, p.y);
    }
    endShape();
  }

  // ==========================================
  // 3. 魔法発動エフェクト（認識された図形の表示）
  // ==========================================
  if (recognizedShape.size() > 0) {
    stroke(elementColor);
    strokeWeight(8);
    fill(elementColor, 100); // 半透明で塗りつぶす
    beginShape();
    for (PVector p : recognizedShape) {
      vertex(p.x, p.y);
    }
    endShape(CLOSE);
  }

  // ==========================================
  // 4. UI（テキスト）表示
  // ==========================================
  fill(0, 150);
  noStroke();
  rect(0, 0, width, 55);
  fill(255);
  textSize(20);
  text(resultText, 10, 25);
  textSize(14);
  text("Cキー: クリア", width - 100, 30);
}

// ==========================================
// 入力処理（キーボード・マウス）
// ==========================================
void mousePressed() {
  // クリックした場所の色をトラッキング色に設定
  int loc = mouseX + mouseY * video.width;
  if (loc >= 0 && loc < video.pixels.length) {
    trackColor = video.pixels[loc];
    smoothedX = mouseX; 
    smoothedY = mouseY;
  }
}

void keyPressed() {
  if (key == ' ') {
    isDrawing = true; 
  } else if (key == ENTER || key == RETURN) {
    evaluateMagicCircle(); 
  } else if (key == 'c' || key == 'C') {
    currentStroke.clear(); 
    recognizedShape.clear(); 
    resultText = "待機中...";
    elementColor = color(255);
  }
}

void keyReleased() {
  if (key == ' ') {
    isDrawing = false; 
  }
}

// ==========================================
// 魔方陣の属性・ダメージ判定処理（OpenCV）
// ==========================================
void evaluateMagicCircle() {
  if (currentStroke.size() < 10) {
    resultText = "魔力が足りません（線が短すぎます）";
    return;
  }

  // 裏画面には「描いた軌跡」をそのまま太い線として描く（塗りつぶさない）
  PGraphics pg = createGraphics(width, height);
  pg.beginDraw();
  pg.background(0); 
  pg.noFill();      // 塗りつぶしをやめる（ねじれバグ防止）
  pg.stroke(255);
  pg.strokeWeight(15); // 線を太くして小さな隙間を強引に繋ぐ
  pg.beginShape();
  for (PVector p : currentStroke) {
    pg.vertex(p.x, p.y);
  }
  pg.endShape();    
  pg.endDraw();

  // OpenCVで解析
  PImage cvImage = pg.get(); 
  opencv.loadImage(cvImage); 
  opencv.gray();             
  opencv.threshold(127);     

// ----------------------------------------------------
  // （pg.endDraw() や opencv.findContours() の下の部分）
  // ----------------------------------------------------
  ArrayList<Contour> contours = opencv.findContours();
  
  if (contours.size() > 0) {
    // 最も大きい輪郭（描いた線の外枠）を探索
    Contour biggest = contours.get(0);
    float maxArea = biggest.area();
    for (Contour c : contours) {
      if (c.area() > maxArea) {
        maxArea = c.area();
        biggest = c;
      }
    }
    
    // OpenCVの強力なネイティブゴムバンド（凸包）変換を使用
    Contour hull = biggest.getConvexHull();
    
    // スケール自動調整（ゴムバンドの横幅に合わせて補正）
    float shapeWidth = hull.getBoundingBox().width;
    hull.setPolygonApproximationFactor(shapeWidth * 0.08); 
    Contour approx = hull.getPolygonApproximation();
    
    // 図形の情報を取得
    int vertices = approx.getPoints().size();
    float area = hull.area(); // 威力はゴムバンドの面積で計算
    int damage = int(area / 200); 

    // エフェクト用に認識された図形の頂点を保存
    recognizedShape.clear();
    for (PVector p : approx.getPoints()) {
      recognizedShape.add(p);
    }

    // 属性とダメージの判定
    if (vertices == 3) {
      resultText = "【炎属性】 ファイア！ (頂点:" + vertices + " / ダメージ:" + damage + ")";
      elementColor = color(255, 50, 50); 
    } else if (vertices == 4) {
      resultText = "【土属性】 アース！ (頂点:" + vertices + " / ダメージ:" + damage + ")";
      elementColor = color(200, 150, 50); 
    } else if (vertices >= 5) {
      resultText = "【水属性】 ウォーター！ (頂点:" + vertices + " / ダメージ:" + damage + ")";
      elementColor = color(50, 150, 255); 
    } else {
      // 失敗パターンA：図形にはなったが、カドの数が1〜2になってしまった場合
      int penaltyDamage = max(1, damage / 2); 
      resultText = "【無属性】 魔力暴走！ (形が乱れた / ダメージ:" + penaltyDamage + ")";
      elementColor = color(200, 200, 200); 
    }
  } else {
    // 面積がないため、「描いた軌跡の長さ（点の数）」を元に強引にダメージを計算する
    int backupDamage = max(1, currentStroke.size() / 5); 
    
    resultText = "【無属性】 魔法不発！ (図形認識不能 / ダメージ:" + backupDamage + ")";
    elementColor = color(150, 150, 150); // より暗いグレー
    recognizedShape.clear(); // 認識エフェクトは無し
  }
}
