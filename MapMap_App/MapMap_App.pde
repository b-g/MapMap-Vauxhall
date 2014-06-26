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

import processing.pdf.*;
import processing.opengl.*;
import java.util.Calendar;

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

void setup() {
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

void draw() {  
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
  if (zoomOut) scale(0.5);
  else scale(1.0);

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
  strokeWeight(0.5);
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
    println("saving to pdf – finishing");
    endRecord();
    println("saving to pdf – done");
  }
}


void drawDestGrid(boolean showTex) {
  if (showGrid) {
    stroke(100);
    strokeWeight(0.25);
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
void keyReleased() {
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
void mousePressed() {
  if (mouseButton == RIGHT) {
    offsetX = mouseX-centerX;
    offsetY = mouseY-centerY;
  }
}

void mouseDragged() {
  updateAchors();
}


// -- update achors --
void updateAchors() {
  anchorsOrig = updateAnchorsOrig(anchors, lines);
  anchorsDest = updateAnchorsDest(anchors, lines);
  anchorMatrices = updateAnchorMatrices(anchorsOrig, anchorsDest);
}

ArrayList<PVector> updateAnchorsOrig(ArrayList<Anchor> theAnchors, ArrayList<Line> theLines) {
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

ArrayList<PVector> updateAnchorsDest(ArrayList<Anchor> theAnchors, ArrayList<Line> theLines) {
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
void loadFile() {
  selectInput("open xml", "fileSelected");  // Opens file chooser
}


// run once xml file is loaded
void fileSelected(File selection) {
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
void saveXML() {
  selectOutput("Select a file to write to:", "outputSelected");  // Opens file chooser
}


void outputSelected(File selection) {

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


String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}

