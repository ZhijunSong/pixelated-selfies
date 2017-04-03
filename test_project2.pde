
import processing.video.*;
import oscP5.*;
import processing.serial.*;
Serial myPort;
int val;

int numPixelsWide, numPixelsHigh; // ?
int blockSize = 2; // Start value
int maxmap; // Variable controlled by position
int frameCount; // Frame counter

color movColors[];
PFont f; //Font

Boolean db; // Toggle Debug View
Boolean Osc;

Float zV; // for OSC
float zM = 0.95; //*************************Magical Z min value of kinnect for mapping

Capture mov;
OscP5 oscP5;

void setup() {
  size(1280, 720);
  maxmap = 640;
  noStroke();
  
  String[] movie = Capture.list();
  if (movie == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    mov = new Capture(this, 640, 480);
  } 
  if (movie.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(movie);

   
    mov = new Capture(this, movie[0]);
    // Or, the settings can be defined based on the text in the list
    //cam = new Capture(this, 640, 480, "Built-in iSight", 30);
    
    // Start capturing the images from the camera
    mov.start();
  


  }

  numPixelsWide = width / blockSize;
  numPixelsHigh = height / blockSize;
  movColors = new color[numPixelsWide * numPixelsHigh]; //?

  f = createFont("Arial", 14);
  textFont(f);

  db = false; //Toogle Value for displaying debug data
  Osc = false; //Osc off by default
  
  
  
  //size(100,100);
  String portName = Serial.list()[2];
  myPort = new Serial(this, portName, 9600);
}

void startOsc(){
    oscP5 = new OscP5(this, 8338); //start oscP5, listening for incoming messages (Kinnect)
    //oscP5 = new OscP5("192.168.1.4", 7003); //iPhone
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("Torso")==true) { //if theOscMessage has the desired address pattern
    //println("Found pattern");
    if (theOscMessage.checkTypetag("fff")) { //if the typetag is the correct
      //println("Found Tag");
      
      
      float thirdValue = theOscMessage.get(2).floatValue(); // get the third osc argument
      
      zV = thirdValue;
      return;
    }
  }
  //println("### received an osc message. with address pattern "+ // Use to see all OSC data coming in
    //theOscMessage.addrPattern()+" typetag "+ theOscMessage.typetag());
}
// Display values from movie
void draw() {
 // mov.volume(0);
 
  if (Osc == true){ // if Osc is running use data for blocksize
     if(zV == null){
        blockSize = 100;
     } else{
       blockSize = int( map(zV, zM, 2, 2,50)); //use Kinnect Z pos to drive size
       //println("Using Osc data");
     }
  }else{
    //println("Using mouse data");
    //println(mouseX);
    if(myPort.available()>0){
      val= myPort.read();
        println(val);

    }
    if (myPort.available()>100) { //Start value of blocksize
       blockSize = 2;
     } 
    if(myPort.available()<300){
        //float r=map(soundVal,50,100,0,1280);
        float r= map(val,1,150,0,1279);
        blockSize = int( map((1280-r), 1, maxmap, 2,50)); //use mouse X pos to drive size
        /*
        value in, (mouse data), value in min (1), max value in, out lower Value, out upper Value
        */
        }
     }
  if (mov.available() == true) {
    mov.read();
    mov.loadPixels();

  }
  image(mov, 0, 0, width, height);
    int count = 0;
    for (int j = 0; j < numPixelsHigh; j++) {
      for (int i = 0; i < numPixelsWide; i++) {
        movColors[count] = mov.get(i*blockSize, j*blockSize);
        count++;
      }
    }
  

  background(255);
  for (int j = 0; j < numPixelsHigh; j++) {
    for (int i = 0; i < numPixelsWide; i++) {
      fill(movColors[j*numPixelsWide + i]);
      rect(i*blockSize, j*blockSize, blockSize, blockSize);

    }
  }


}



void keyPressed() {
  if (key == 'o') {
    if(Osc == true){
      Osc = false;
       oscP5.stop();
      //println("Osc disabled");
    }else{
     //println("Osc enabled");
     Osc = true;
     startOsc();
    }
  }
}