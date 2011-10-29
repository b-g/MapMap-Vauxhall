public class Drager 
{
  PVector p;
  float rectSize;
  float rectRadius;
  color col;
  color colOver;
  boolean isOver = false;
  boolean isDragging = false;

  public Drager (float x, float y, float rectSize, color col) {
    app.registerMouseEvent(this); // app is global :(
    this.p = new PVector(x, y);
    this.rectSize = rectSize;
    this.rectRadius = rectSize/2;
    this.col = col;
    this.colOver = color(red(col), green(col), blue(col), 128);
  }

  void preRemove() {
    app.unregisterMouseEvent(this);
  }

  void draw() {
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

  boolean isOver() {
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

    switch (event.getID()) {
    case MouseEvent.MOUSE_PRESSED:
      if (isOver) isDragging = true;
      break;
    case MouseEvent.MOUSE_RELEASED:
      isDragging = false;
      break;
    }
  }
}

