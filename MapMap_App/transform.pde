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

void transform(PVector p, ArrayList<PVector> origs, ArrayList<PVector> dests, ArrayList<PMatrix2D> matrices) {
  // calc distances between point and all original anchors  
  float[] dists = new float[origs.size()];
  float[] distfacs = new float[origs.size()];
  float sum = 0;
  for (int i = 0; i < dists.length; i++) {
    dists[i] = PVector.dist(p, origs.get(i));
    //if (dists[i] == 0) dists[i] = 0.00001;
    distfacs[i] = 1.0 / (pow(dists[i], 2) + 1);
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
ArrayList<PMatrix2D> updateAnchorMatrices(ArrayList<PVector> origs, ArrayList<PVector> dests) {
  //println("updateAnchorMatrices");
  float fac = 1.0 / (origs.size()-1);

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
float angleDifference(float theAngle1, float theAngle2) {
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

