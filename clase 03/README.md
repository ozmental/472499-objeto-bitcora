
## processing

int n = 528;
float latMin = -33.46095f, latMax = -33.425541f;
float lonMin = -70.634575f, lonMax = -70.613652f;

float margin = 60;
float animIndex = 0;
boolean animating = true;
float animSpeed = 2.0;

void setup() {
  size(900, 800);
  smooth(4);
  textFont(createFont("Monospaced", 12));
}

void draw() {
  background(20, 22, 30);

  // Título
  fill(200, 200, 220);
  textSize(14);
  textAlign(LEFT);
  text("GPS Track Visualizer", margin, 30);
  textSize(11);
  fill(120, 130, 160);
  text(n + " puntos  |  Presiona ESPACIO para animar / pausar  |  R para reiniciar", margin, 50);

  // Bounding box lat/lon -> pantalla
  float drawW = width - margin * 2;
  float drawH = height - margin * 2 - 40;

  // Dibujar fondo del mapa
  noFill();
  stroke(40, 45, 60);
  strokeWeight(1);
  rect(margin, margin + 40, drawW, drawH);

  // Grid
  stroke(35, 40, 55);
  strokeWeight(0.5);
  int gridLines = 6;
  for (int i = 0; i <= gridLines; i++) {
    float x = margin + drawW * i / gridLines;
    float y = (margin + 40) + drawH * i / gridLines;
    line(x, margin + 40, x, margin + 40 + drawH);
    line(margin, y, margin + drawW, y);
  }

  // Recorrido completo (gris tenue de fondo)
  stroke(60, 65, 90);
  strokeWeight(1.5);
  noFill();
  beginShape();
  for (int i = 0; i < n; i++) {
    float x = map(lons[i], lonMin, lonMax, margin, margin + drawW);
    float y = map(lats[i], latMax, latMin, margin + 40, margin + 40 + drawH);
    vertex(x, y);
  }
  endShape();

  // Recorrido animado (gradiente de color)
  int endIdx = animating ? (int)animIndex : n - 1;
  if (endIdx >= 2) {
    for (int i = 1; i <= endIdx && i < n; i++) {
      float t = (float)i / n;
      // Color: azul cian -> violeta -> naranja
      float r = lerp(0, 255, t);
      float g = lerp(200, 80, t);
      float b = lerp(255, 50, t);
      stroke(r, g, b, 200);
      strokeWeight(2.5);
      float x1 = map(lons[i-1], lonMin, lonMax, margin, margin + drawW);
      float y1 = map(lats[i-1], latMax, latMin, margin + 40, margin + 40 + drawH);
      float x2 = map(lons[i], lonMin, lonMax, margin, margin + drawW);
      float y2 = map(lats[i], latMax, latMin, margin + 40, margin + 40 + drawH);
      line(x1, y1, x2, y2);
    }
  }

  // Punto inicio (verde)
  float sx = map(lons[0], lonMin, lonMax, margin, margin + drawW);
  float sy = map(lats[0], latMax, latMin, margin + 40, margin + 40 + drawH);
  fill(80, 220, 120);
  noStroke();
  ellipse(sx, sy, 10, 10);
  fill(80, 220, 120, 180);
  textSize(10);
  textAlign(LEFT);
  text("inicio", sx + 7, sy + 4);

  // Punto actual / fin
  if (endIdx > 0 && endIdx < n) {
    float ex = map(lons[endIdx], lonMin, lonMax, margin, margin + drawW);
    float ey = map(lats[endIdx], latMax, latMin, margin + 40, margin + 40 + drawH);
    // Pulso
    float pulse = sin(frameCount * 0.15) * 4;
    noFill();
    stroke(255, 120, 60, 100);
    strokeWeight(1.5);
    ellipse(ex, ey, 16 + pulse, 16 + pulse);
    fill(255, 120, 60);
    noStroke();
    ellipse(ex, ey, 8, 8);
  }

  // Progreso
  float prog = (float)endIdx / (n - 1);
  float barW = drawW * 0.6f;
  float barX = margin;
  float barY = height - 22;
  fill(40, 45, 60);
  noStroke();
  rect(barX, barY, barW, 6, 3);
  fill(0, 180, 255);
  rect(barX, barY, barW * prog, 6, 3);
  fill(160, 170, 200);
  textSize(10);
  textAlign(LEFT);
  text(nf(prog * 100, 0, 1) + "%  punto " + endIdx + "/" + (n-1), barX + barW + 10, barY + 7);

  // Animación
  if (animating) {
    animIndex += animSpeed;
    if (animIndex >= n) {
      animIndex = n - 1;
      animating = false;
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    if (!animating && animIndex >= n - 1) {
      animIndex = 0;
      animating = true;
    } else {
      animating = !animating;
    }
  }
  if (key == 'r' || key == 'R') {
    animIndex = 0;
    animating = true;
  }
  if (key == '+') animSpeed = min(animSpeed + 0.5, 20);
  if (key == '-') animSpeed = max(animSpeed - 0.5, 0.5);
}
