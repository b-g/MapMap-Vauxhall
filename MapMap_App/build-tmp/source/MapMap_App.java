import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.pdf.*; 
import processing.opengl.*; 
import java.util.Calendar; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class MapMap_App extends PApplet {

/*
 Benedikt Gross, Hartmut Bohnacker (mapping algorithmen, see transform.pde)
 Copyright (c) 2011 
 
 http://www.looksgood.de/log/2011/10/mapmap-vauxhall-mashup-mental-maps-and-openstreetmap
 
 This sourcecode is free software; you can redistribute it and/or modify it under the terms 
 of the GNU Lesser General Public License as published by the Free Software Foundation; 
 either version 2.1 of the License, or (at your option) any later version.
 
 This Sourcecode is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License along with this 
 library; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
 Boston, MA 02110, USA
 */

/** 
 * MOUSE
 * position x/y + drag        : move/edit anchor points
 * right press + drag         : pan canvas
 * 
 * KEYS
 * 1-6                        : switch view mode
 * p/l                        : add anchor/line on current mouse pos
 * delete/backspace           : delete anchor/line on current mouse pos
 * g                          : toggle grid view (only in mode 4-6)
 * a                          : toggle anchor view (only in mode 4-6)
 * s                          : save mapping declaration to xml file
 * o                          : open mapping declaration from xml file
 * e                          : save png and pdf of current view
 * 0                          : zoom in/out
 */





// grab a reference to the applet ... is used to register mouse events
PApplet app = this;

int mode = 4;

PImage imgOrig;
PImage imgDest;

float tileSize = 20;
boolean showGrid = true;
boolean showAnchors = true;

ArrayList<Anchor> anchors = new ArrayList<Anchor>();
ArrayList<Line> lines = new ArrayList<Line>();

ArrayList<PVector> anchorsOrig;
ArrayList<PVector> anchorsDest;
ArrayList<PMatrix2D> anchorMatrices;

int canvasWidth = -1, canvasHeight = -1;

// panning the canvas
int centerX = 0, centerY = 0, offsetX = 0, offsetY = 0;
boolean zoomOut = false;
// mouse coordinates with mapped panning
int mX = 0, mY = 0;

boolean savePngPdf = false;

public void setup() {
  size(displayWidth-100, displayHeight-100, OPENGL);
  frame.setResizable(true);
  println("helo");

  imgOrig = loadImage("orig.png");
  imgDest = loadImage("dest.png");

  canvasWidth = imgOrig.width;
  canvasHeight = imgOrig.height;

  cursor(CROSS);
  noStroke();

  anchors.add( new Anchor(0, 0) );
  anchors.add( new Anchor(canvasWidth, 0) );
  anchors.add( new Anchor(canvasWidth, canvasHeight) );
  anchors.add( new Anchor(0, canvasHeight) );

  updateAchors();
}

public void draw() {  
  if (savePngPdf) {
    saveFrame(timestamp()+".png");
    beginRecord(PDF, timestamp()+".pdf");
  }

  rectMode(CENTER);

  if (mousePressed && mouseButton == RIGHT) {
    centerX = mouseX-offsetX;
    centerY = mouseY-offsetY;
  } 
  
  // map mouse to panned coordinates
  if (!zoomOut) {
    mX = mouseX-centerX;
    mY = mouseY-centerY;
  } 
  else {
    mX = (mouseX-centerX)*2;
    mY = (mouseY-centerY)*2;
  }

  translate(centerX, centerY);
  if (zoomOut) scale(0.5f);
  else scale(1.0f);

  background(255);
  tint(255, 255);

  switch (mode) {

    // only orig image
  case 1:
    image(imgOrig, 0, 0);
    break;

    // only dest image
  case 2:
    image(imgDest, 0, 0);
    break;

    // dest with alpha on top of orig
  case 3:
    image(imgOrig, 0, 0);
    tint(255, 100);
    image(imgDest, 0, 0);
    break;

    // dest image + dest mapped to orig
  case 4:
    tint(255, 255);
    drawDestGrid(true);

    tint(255, 100);
    image(imgDest, 0, 0);
    break;

    // dest mapped to orig
  case 5:
    drawDestGrid(true);
    break;

    // dest grid without tex
  case 6:
    drawDestGrid(false);
    break;
  }

  // bounding box
  strokeWeight(0.5f);
  stroke(128);
  noFill();
  rectMode(CORNER);
  rect(0, 0, canvasWidth, canvasHeight);

  // show all anchors
  rectMode(CENTER);
  if (showAnchors) {
    for (Anchor a : anchors) { 
      a.draw();
    }
    for (Line l : lines) { 
      l.draw();
    }
  }

  if (savePngPdf) {
    savePngPdf = false;
    println("saving to pdf \u2013 finishing");
    endRecord();
    println("saving to pdf \u2013 done");
  }
}


public void drawDestGrid(boolean showTex) {
  if (showGrid) {
    stroke(100);
    strokeWeight(0.25f);
  } 
  else {
    noStroke();
  }
  // mapping
  for (float y=0; y<canvasHeight; y+=tileSize) {
    beginShape(QUAD_STRIP);
    if (showTex) texture(imgOrig);
    else noFill();
    for (float x=0; x<=canvasWidth; x+=tileSize) {
      float y1 = y;
      float y2 = y+tileSize;
      float u = x;
      float v1 = y1;
      float v2 = y2;
      PVector newP1 = new PVector(x, y1);
      transform(newP1, anchorsOrig, anchorsDest, anchorMatrices);
      PVector newP2 = new PVector(x, y2);
      transform(newP2, anchorsOrig, anchorsDest, anchorMatrices);
      if (showTex) vertex(newP1.x, newP1.y, u, v1);
      else vertex(newP1.x, newP1.y);
      if (showTex) vertex(newP2.x, newP2.y, u, v2);
      else vertex(newP2.x, newP2.y);
    }
    endShape();
  }
}


// -- interaction events --
public void keyReleased() {
  if (key=='1') mode = 1;
  if (key=='2') mode = 2;
  if (key=='3') mode = 3;
  if (key=='4') mode = 4;
  if (key=='5') mode = 5;
  if (key=='6') mode = 6;

  if (key == '0') zoomOut = !zoomOut;

  if (key=='g' || key=='G') showGrid = !showGrid;
  if (key=='a' || key=='A') showAnchors = !showAnchors;

  if (key=='o' || key=='O') loadFile();
  if (key=='s' || key=='S') saveXML();

  if (key=='e' || key=='E') {
    savePngPdf = true; 
    println("saving to pdf - starting");
  }

  if (key==BACKSPACE || key==DELETE) {
    for (int i = 0; i<anchors.size(); i++) {
      if (anchors.get(i).isOver()) {
        anchors.get(i).preRemove();
        anchors.remove(i);
      }
    }
    for (int i = 0; i<lines.size(); i++) {
      if (lines.get(i).isOver()) {
        lines.get(i).preRemove();
        lines.remove(i);
      }
    }
    updateAchors();
  }
  if (key=='p' || key=='P') {
    anchors.add( new Anchor(mX, mY) );
    updateAchors();
  }
  if (key=='l' || key=='L') {
    lines.add( new Line(mX, mY, mX+100, mY) );
    updateAchors();
  }
}

// panning
public void mousePressed() {
  if (mouseButton == RIGHT) {
    offsetX = mouseX-centerX;
    offsetY = mouseY-centerY;
  }
}

public void mouseDragged() {
  updateAchors();
}


// -- update achors --
public void updateAchors() {
  anchorsOrig = updateAnchorsOrig(anchors, lines);
  anchorsDest = updateAnchorsDest(anchors, lines);
  anchorMatrices = updateAnchorMatrices(anchorsOrig, anchorsDest);
}

public ArrayList<PVector> updateAnchorsOrig(ArrayList<Anchor> theAnchors, ArrayList<Line> theLines) {
  ArrayList<PVector> points = new ArrayList<PVector>();
  for (Anchor a : theAnchors) { 
    points.add(a.orig.p);
  }
  for (Line l : theLines) {
    for (PVector p : l.origInterpolate) {
      points.add(p);
    }
  }
  return points;
}

public ArrayList<PVector> updateAnchorsDest(ArrayList<Anchor> theAnchors, ArrayList<Line> theLines) {
  ArrayList<PVector> points = new ArrayList<PVector>();
  for (Anchor a : theAnchors) { 
    points.add(a.dest.p);
  }
  for (Line l : theLines) {
    for (PVector p : l.destInterpolate) {
      points.add(p);
    }
  }
  return points;
}


// -- xml load file --
public void loadFile() {
  selectInput("open xml", "fileSelected");  // Opens file chooser
}


// run once xml file is loaded
public void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    // return selection.getAbsolutePath();

    String openFilepath = selection.getAbsolutePath();
    println( openFilepath );

    if (openFilepath != null) {
      println(openFilepath);

      anchors = new ArrayList<Anchor>();
      lines = new ArrayList<Line>();

      XML xml = loadXML(openFilepath);

      XML[] linesXml = xml.getChildren("line");
      for (XML i : linesXml) {
        Line l = new Line ( i.getFloat("orig_a_x"), i.getFloat("orig_a_y"), i.getFloat("orig_b_x"), i.getFloat("orig_b_y"), 
        i.getFloat("dest_a_x"), i.getFloat("dest_a_y"), i.getFloat("dest_b_x"), i.getFloat("dest_b_y") );
        lines.add( l );
      }

      XML[] anchorsXml = xml.getChildren("line");
      for (XML i : anchorsXml) {
        Anchor a = new Anchor ( i.getFloat("orig_x"), i.getFloat("orig_y"), i.getFloat("dest_x"), i.getFloat("dest_y") );
        anchors.add( a );
      }

      updateAchors();
    }
  }
}


// -- xml save points --
public void saveXML() {
  selectOutput("Select a file to write to:", "outputSelected");  // Opens file chooser
}


public void outputSelected(File selection) {

  String savePath = selection.getAbsolutePath();

  if (savePath != null) {
    println("save points to xml -> start");
    XML xml = new XML("map_data");

    XML bounds = xml.addChild("bounds");
    bounds.setInt("min_width", 0);
    bounds.setInt("max_width", canvasWidth);
    bounds.setInt("min_height", 0);
    bounds.setInt("max_height", canvasHeight);

    for (int i=0; i<anchorsOrig.size(); i++) {
      XML dest_orig = xml.addChild("dest_orig");
      dest_orig.setFloat("orig_x", anchorsOrig.get(i).x);
      dest_orig.setFloat("orig_y", anchorsOrig.get(i).y);
      dest_orig.setFloat("dest_x", anchorsDest.get(i).x);
      dest_orig.setFloat("dest_y", anchorsDest.get(i).y);
    }

    for (int i=0; i<anchors.size(); i++) {
      XML anchor = xml.addChild("anchor");
      anchor.setFloat("orig_x", anchors.get(i).orig.p.x);
      anchor.setFloat("orig_y", anchors.get(i).orig.p.y);
      anchor.setFloat("dest_x", anchors.get(i).dest.p.x);
      anchor.setFloat("dest_y", anchors.get(i).dest.p.y);
    }

    for (int i=0; i<lines.size(); i++) {
      XML line = xml.addChild("line");
      line.setFloat("orig_a_x", lines.get(i).origA.p.x);
      line.setFloat("orig_a_y", lines.get(i).origA.p.y);
      line.setFloat("orig_b_x", lines.get(i).origB.p.x);
      line.setFloat("orig_b_y", lines.get(i).origB.p.y);
      line.setFloat("dest_a_x", lines.get(i).destA.p.x);
      line.setFloat("dest_a_y", lines.get(i).destA.p.y);
      line.setFloat("dest_b_x", lines.get(i).destB.p.x);
      line.setFloat("dest_b_y", lines.get(i).destB.p.y);
    }

    // write file
    PrintWriter xmlfile = createWriter(savePath);  
    xmlfile.println(xml.toString());
    xmlfile.flush(); // Writes the remaining data to the file
    xmlfile.close(); // Finishes the file
    println("save points to xml -> done");
  }
}


public String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}

public class Anchor 
{  
  Drager orig;
  Drager dest;
  
  int origCol = color(255, 130, 30);
  int destCol = color(255, 50, 55);
  float origSize = 10;
  float destSize = 20;

  public Anchor (float x, float y) {
    orig = new Drager(x, y, origSize, origCol);
    dest = new Drager(x, y, destSize, destCol);
  }
  
  public Anchor (float origX, float origY, float destX, float destY) {
    orig = new Drager(origX, origY, origSize, origCol);
    dest = new Drager(destX, destY, destSize, destCol);
  }

  public void draw() {
    dest.draw();
    orig.draw();
  }
  
  public void preRemove() {
    orig.preRemove();
    dest.preRemove();
  }

  public boolean isOver() {
    return orig.isOver() || dest.isOver();
  } 
}
public class Drager 
{
  PVector p;
  float rectSize;
  float rectRadius;
  int col;
  int colOver;
  boolean isOver = false;
  boolean isDragging = false;

  public Drager (float x, float y, float rectSize, int col) {
    app.registerMethod("mouseEvent", this); // app is global :(
    this.p = new PVector(x, y);
    this.rectSize = rectSize;
    this.rectRadius = rectSize/2;
    this.col = col;
    this.colOver = color(red(col), green(col), blue(col), 128);
  }

  public void preRemove() {
    app.unregisterMouseEvent(this);
  }

  public void draw() {
    if (isDragging) {
      //p.x = mouseX;
      //p.y = mouseY;
      
      // mouse coordinates mapped to zoom factor
      p.x = mX;
      p.y = mY;
    }

    if (isOver) {
      strokeWeight(1);
      stroke(0);
      noFill();
    }  
    else {
      noStroke();
      fill(col);
    }
    rect(p.x, p.y, rectSize, rectSize);
  }

  public boolean isOver() {
    // mX, mY are global :(
    //if (mouseX >= p.x-rectRadius && mouseX <= p.x+rectRadius && mouseY >= p.y-rectRadius && mouseY <= p.y+rectRadius) {
    if (mX >= p.x-rectRadius && mX <= p.x+rectRadius && mY >= p.y-rectRadius && mY <= p.y+rectRadius) {
      return true;
    } 
    else {
      return false;
    }
  }



  public void mouseEvent(MouseEvent event) {
    isOver = isOver();

    switch (event.getAction()) {
    case MouseEvent.PRESS:
      if (isOver) isDragging = true;
      break;
    case MouseEvent.RELEASE:
      isDragging = false;
      break;
    }
  }
}

public class Line
{
  Drager origA;
  Drager origB;
  Drager destA;
  Drager destB;

  float origDist;
  float destDist;
  float interpolateSize = 20;
  float interpolateRectSize = 3;
  ArrayList<PVector> origInterpolate;
  ArrayList<PVector> destInterpolate;

  int origCol = color(255, 130, 30);
  int destCol = color(255, 50, 55);
  float origSize = 10;
  float destSize = 20;

  public Line (float x1, float y1, float x2, float y2) {
    origA = new Drager(x1, y1, origSize, origCol);
    origB = new Drager(x2, y2, origSize, origCol);
    destA = new Drager(x1, y1, destSize, destCol);
    destB = new Drager(x2, y2, destSize, destCol);
    update();
  }

  public Line (float origAX, float origAY, float origBX, float origBY, 
  float destAX, float destAY, float destBX, float destBY) {
    origA = new Drager(origAX, origAY, origSize, origCol);
    origB = new Drager(origBX, origBY, origSize, origCol);
    destA = new Drager(destAX, destAY, destSize, destCol);
    destB = new Drager(destBX, destBY, destSize, destCol);
    update();
  }

  public void update() {
    origDist = PVector.dist(origA.p, origB.p);
    destDist = PVector.dist(destA.p, destB.p);
    int count = round(destDist/interpolateSize);
    origInterpolate = lerpToPoint(origA.p, origB.p, count);
    destInterpolate = lerpToPoint(destA.p, destB.p, count);
  }

  public void draw() {
    update();
  
    destB.draw(); 
    destA.draw();
    if (destA.isOver() || destB.isOver()) strokeWeight(2);
    else strokeWeight(1);
    stroke(destCol);
    line(destA.p.x, destA.p.y, destB.p.x, destB.p.y);

    origB.draw(); 
    origA.draw();
    if (origA.isOver() || origB.isOver()) strokeWeight(2);
    else strokeWeight(1);
    stroke(origCol);
    line(origA.p.x, origA.p.y, origB.p.x, origB.p.y);
    
    stroke(0);
    strokeWeight(1);
    for (PVector i : destInterpolate){ point(i.x, i.y); }
    for (PVector i : origInterpolate){ point(i.x, i.y); }
  }

  public void preRemove() {
    origA.preRemove();
    origB.preRemove();
    destA.preRemove();
    destB.preRemove();
  }

  public boolean isOver() {
    return origA.isOver() || destA.isOver() || origB.isOver() || destB.isOver();
  }

  public ArrayList<PVector> lerpToPoint(PVector p1, PVector p2, int count) {
    ArrayList<PVector> points = new ArrayList<PVector>(); 
    for (float i=0; i<=count; i++) {
      float x = lerp(p1.x, p2.x, i/count);
      float y = lerp(p1.y, p2.y, i/count);
      points.add( new PVector(x, y) );
    }
    return points;
  }
}

/*
 Hartmut Bohnacker, http://hartmut-bohnacker.de/
 Copyright (c) 2011
 
 This sourcecode is free software; you can redistribute it and/or modify it under the terms 
 of the GNU Lesser General Public License as published by the Free Software Foundation; 
 either version 2.1 of the License, or (at your option) any later version.
 
 This sourcecode is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License along with this 
 library; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
 Boston, MA 02110, USA
 */
 
// howdy stranger, if you know a mathematical/official name of this kind of mapping algorithmen ... 
// please drop a note to me (hartmut) :)

public void transform(PVector p, ArrayList<PVector> origs, ArrayList<PVector> dests, ArrayList<PMatrix2D> matrices) {
  // calc distances between point and all original anchors  
  float[] dists = new float[origs.size()];
  float[] distfacs = new float[origs.size()];
  float sum = 0;
  for (int i = 0; i < dists.length; i++) {
    dists[i] = PVector.dist(p, origs.get(i));
    //if (dists[i] == 0) dists[i] = 0.00001;
    distfacs[i] = 1.0f / (pow(dists[i], 2) + 1);
    sum += distfacs[i];
  }

  // calc attraction weights (sum of all weights must be 1)
  float[] weights = new float[dists.length];
  for (int i = 0; i < dists.length; i++) {
    weights[i] = distfacs[i] / sum;
  }

  // apply matrix-transforms to the point
  PVector dvecOffsetSum = new PVector();
  for (int i = 0; i < origs.size(); i++) {
    // delta vector from orig-anchor to the point
    PVector dvec = PVector.sub(p, origs.get(i));

    // apply the matrix of this anchor to that delta vector 
    PVector dvecres = new PVector();
    matrices.get(i).mult(dvec, dvecres);

    // offset between the delta vector and the transformed delta vector 
    PVector dvecOffset = PVector.sub(dvecres, dvec);

    // multiply this offset by the weight of this anchor
    dvecOffset.mult(weights[i]);

    // add up all offset
    dvecOffsetSum.add(dvecOffset);
  }
  // add the sum of all offsets to the point
  p.add(dvecOffsetSum);
}

// calculate a transformation matrix for each anchor.
// this matrix reflects the translation of the anchor and the rotation and scaling depending on
// the (possibly) changed positions of all other anchors.
public ArrayList<PMatrix2D> updateAnchorMatrices(ArrayList<PVector> origs, ArrayList<PVector> dests) {
  //println("updateAnchorMatrices");
  float fac = 1.0f / (origs.size()-1);

  ArrayList<PMatrix2D> matrices = new ArrayList<PMatrix2D>();

  for (int i = 0; i < origs.size(); i++) {
    matrices.add(new PMatrix2D());
    matrices.get(i).translate(dests.get(i).x - origs.get(i).x, dests.get(i).y - origs.get(i).y);

    for (int j = 0; j < matrices.size(); j++) {
      if (i != j) {
        float w1 = atan2(origs.get(j).y - origs.get(i).y, origs.get(j).x - origs.get(i).x);
        float w2 = atan2(dests.get(j).y - dests.get(i).y, dests.get(j).x - dests.get(i).x);
        float w = angleDifference(w2, w1) * fac;
        matrices.get(i).rotate(w);

        float d1 = PVector.dist(origs.get(j), origs.get(i));
        float d2 = PVector.dist(dests.get(j), dests.get(i));
        float s = d2 / d1;
        
        if (d1 == 0 && d2 == 0) s = 1;
        else if (d1 == 0) s = 10;
        
        s = pow(s, fac);
        matrices.get(i).scale(s);
      }
    }
  }
  return matrices;
}

// helping function that calculates the difference of two angles
public float angleDifference(float theAngle1, float theAngle2) {
  float a1 = (theAngle1 % TWO_PI + TWO_PI) % TWO_PI;
  float a2 = (theAngle2 % TWO_PI + TWO_PI) % TWO_PI;

  if (a2 > a1) {
    float d1 = a2 - a1;
    float d2 = a1 + TWO_PI - a2;
    if (d1 <= d2) {
      return -d1;
    } 
    else {
      return d2;
    }
  } 
  else {
    float d1 = a1 - a2;
    float d2 = a2 + TWO_PI - a1;
    if (d1 <= d2) {
      return d1;
    } 
    else {
      return -d2;
    }
  }
}

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "MapMap_App" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
