/*
 just drop a folder which includes a .osm file and a saved xml 
 file from the MapMap_App ... to get an transformed .osm file. 
 the new file will be saved in the same folder. 
 
 The droplet expects that the dimensions/aspect ratio of 
 MapMap_App/data/dest.png and the .osm file are the same.
 
 http://www.looksgood.de/log/2011/10/mapmap-vauxhall-mashup-mental-maps-and-openstreetmap
 */

import sojamo.drop.*;

SDrop drop;

boolean loaded = false;

ArrayList<PVector> anchorsOrig;
ArrayList<PVector> anchorsDest;
ArrayList<PMatrix2D> anchorMatrices;
int canvasWidth = -1, canvasHeight = -1;

color red = color(255, 0, 0);
color green = color(0, 255, 0);
color col = red;

color origCol = color(255, 130, 30);
color destCol = color(255, 50, 55);

void setup() {
  size(200, 200);
  frame.setResizable(true);
  drop = new SDrop(this);
}

void draw() {
  background(col);
  translate(50, 50);
  scale(0.25);

  if (loaded) {
    for (PVector p : anchorsOrig) {
      fill(origCol);
      rect(p.x, p.y, 10, 10);
    }
    for (PVector p : anchorsDest) {
      fill(destCol);
      rect(p.x, p.y, 20, 20);
    }
    noFill();
    rect(0, 0, canvasWidth, canvasHeight);
  }
}

void dropEvent(DropEvent theDropEvent) {
  if (theDropEvent.isFile()) {
    File myFile = theDropEvent.file();

    if (myFile.isDirectory()) {
      File[] files = myFile.listFiles(new fileFilter());

      for (File f : files) {
        String name = f.getName();
        if (name.endsWith(".xml")) {
          //println(f.getName());
          loadAnchors(f.getPath());
          anchorMatrices = updateAnchorMatrices(anchorsOrig, anchorsDest);
        }
      }

      for (File f : files) {
        String name = f.getName();
        if (name.endsWith(".osm")) {
          //println(f.getName());
          transformOSM(f.getAbsolutePath(), myFile.getAbsolutePath()+"/"+"transformed_"+timestamp()+".osm");
        }
      }

      col = green;
      loaded = true;
    }
  }
}

void loadAnchors(String openFilepath) {
  println("\nloadPoints -> start");

  anchorsOrig = new ArrayList<PVector>();
  anchorsDest = new ArrayList<PVector>();

  XML xml = loadXML(openFilepath);

  XML bounds = xml.getChild("bounds");
  canvasHeight = bounds.getInt("max_height");
  canvasWidth = bounds.getInt("max_width");

  XML[] dest_orig = xml.getChildren("dest_orig");
  for (XML i : dest_orig) {
    PVector orig = new PVector(i.getFloat("orig_x"), i.getFloat("orig_y"));
    anchorsOrig.add( orig );
    PVector dest = new PVector(i.getFloat("dest_x"), i.getFloat("dest_y"));
    anchorsDest.add( dest );
    //println(orig);
    //println(dest);
  }
  println("anchorsOrig size: "+anchorsOrig.size());
  println("anchorsDest size: "+anchorsDest.size());
  println("loadPoints -> end");
}

void transformOSM(String openFilepath, String saveFilepath) {
  println("\ntransformOSM -> start");
  XML openstreetmap = loadXML(openFilepath);

  XML bounds = openstreetmap.getChild("bounds");
  // x
  float maxlon = bounds.getFloat("maxlon");
  float minlon = bounds.getFloat("minlon");
  // y
  float maxlat = bounds.getFloat("maxlat");
  float minlat = bounds.getFloat("minlat");

  float lonWidth = maxlon - minlon;
  float latHeight = maxlat - minlat;
  println(lonWidth + " x " + latHeight);
  println(canvasWidth + " x " + canvasHeight);

  XML[] nodes = openstreetmap.getChildren("node");
  for (int i = 0; i < nodes.length; i++) {
    XML node = nodes[i];
    float lon = node.getFloat("lon"); //x
    float lat = node.getFloat("lat"); //y
    float x = map(lon, minlon, maxlon, 0, canvasWidth);
    float y = map(lat, maxlat, minlat, 0, canvasHeight);
    PVector newP = new PVector(x, y);

    transform(newP, anchorsOrig, anchorsDest, anchorMatrices);

    x = map(newP.x, 0, canvasWidth, minlon, maxlon);
    y = map(newP.y, 0, canvasHeight, maxlat, minlat);

    node.setFloat("lon", x );
    node.setFloat("lat", y );
  }

  PrintWriter xmlfile = createWriter(saveFilepath);  
  xmlfile.println(openstreetmap.toString());
  xmlfile.flush();
  xmlfile.close();
  println("transformOSM -> done");
}

class fileFilter implements FileFilter {
  public boolean accept(File pathname) {
    if (pathname.getName().endsWith(".osm"))
      return true;
    if (pathname.getName().endsWith(".xml"))
      return true;
    return false;
  }
}

String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}

