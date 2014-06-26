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

  color origCol = color(255, 130, 30);
  color destCol = color(255, 50, 55);
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

  void update() {
    origDist = PVector.dist(origA.p, origB.p);
    destDist = PVector.dist(destA.p, destB.p);
    int count = round(destDist/interpolateSize);
    origInterpolate = lerpToPoint(origA.p, origB.p, count);
    destInterpolate = lerpToPoint(destA.p, destB.p, count);
  }

  void draw() {
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

  void preRemove() {
    origA.preRemove();
    origB.preRemove();
    destA.preRemove();
    destB.preRemove();
  }

  boolean isOver() {
    return origA.isOver() || destA.isOver() || origB.isOver() || destB.isOver();
  }

  ArrayList<PVector> lerpToPoint(PVector p1, PVector p2, int count) {
    ArrayList<PVector> points = new ArrayList<PVector>(); 
    for (float i=0; i<=count; i++) {
      float x = lerp(p1.x, p2.x, i/count);
      float y = lerp(p1.y, p2.y, i/count);
      points.add( new PVector(x, y) );
    }
    return points;
  }
}

