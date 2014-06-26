public class Anchor 
{  
  Drager orig;
  Drager dest;
  
  color origCol = color(255, 130, 30);
  color destCol = color(255, 50, 55);
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

  void draw() {
    dest.draw();
    orig.draw();
  }
  
  void preRemove() {
    orig.preRemove();
    dest.preRemove();
  }

  boolean isOver() {
    return orig.isOver() || dest.isOver();
  } 
}
