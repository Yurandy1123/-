import processing.video.*;
import jp.nyatla.nyar4psg.*;

Capture cam;
MultiMarker nya;

//ステータス
int playerHP = 100;
int playerMaxHP = 100;
int enemyHP = 120;

float attackBuff = 1.0;

String message = "";

//クールタイム
int lastUseFrame = -100;
int cooldown = 300; //5秒

PShape[] itemModel = new PShape[3];

void setup() {
  size(640, 480, P3D);
  pixelDensity(1);  //高解像度ディスプレイ対策（ズレ防止のため重要）
  colorMode(RGB, 255);  //RGB色空間（０～255）
  println(MultiMarker.VERSION);  //ライブラリのバージョン表示
  
  String[] cameras = Capture.list();
  printArray(cameras);

  //カメラ選択
  cam = new Capture(this, cameras[2]);
  
  //ARエンジン初期化
  nya=new MultiMarker(this,width,height,"camera_para.dat",NyAR4PsgConfig.CONFIG_PSG);
  //3つのマーカ登録
  nya.addNyIdMarker(0,40);//id=0
  nya.addNyIdMarker(1,40);//id=1
  nya.addNyIdMarker(2,40);//id=2
  
  itemModel[0] = loadShape("herb.obj");
  itemModel[1] = loadShape("bomb.obj");
  itemModel[2] = loadShape("seed.obj");
  
  println("herb = " + itemModel[0]);
  println("bomb = " + itemModel[1]);
  println("seed = " + itemModel[2]);

  
  //カメラ開始
  cam.start();
}

void draw(){
  if (cam.available()){
      cam.read();
  }
  
  nya.detect(cam);  //カメラ映像からマーカ検出
  
  background(0);  //背景を黒に,カメラ映像を表示
  nya.drawBackground(cam);
  
  for ( int i = 0 ; i < 3 ; i++ ){
    if ( (!nya.isExist(i)) ){
      continue;
    }
    
    //AR座標に切り替え、マーカー位置に座標系を移動
    //以降の描画はマーカー基準に
    nya.beginTransform(i);
    
    pushMatrix();
    
    lights();
    
    translate(0, 0, 20);
    //fill(0, 225, 0);
    //box(40);
    
    scale(10);
    
    rotateX(radians(90));
    
    shape(itemModel[i]);
    
    popMatrix();
    
    nya.endTransform();    //座標を戻す、通常の座標系に
    
    useItemByMarker(i);
  }
  
  drawUI();

}

void useItemByMarker ( int id ){
  if (frameCount - lastUseFrame < cooldown) return;
  lastUseFrame = frameCount;

  if( id == 0 ){
    useHerb();
  } else if ( id == 1 ){
    useBomb();
  }else if ( id == 2 ){
    usePowerSeed();
  }
}

void useHerb() {
  int heal = 30;
  playerHP = min(playerHP + heal, playerMaxHP);
  message = "やくそうで回復！";
}

void useBomb() {
  int damage = 20;
  enemyHP = max(enemyHP - damage, 0);
  message = "ばくだんで攻撃！";
}

void usePowerSeed() {
  attackBuff = 1.5;
  message = "攻撃力アップ！";
}


void drawUI() {
  fill(0, 150);
  rect(0, 400, width, 80);

  fill(255);
  textSize(16);

  text("Player HP: " + playerHP + "/" + playerMaxHP, 10, 420);
  text("Enemy HP: " + enemyHP, 10, 440);
  text("Buff: " + attackBuff, 10, 460);

  text(message, 10, 480);
}
