

Table table;
int currentRow = 0;
float amplitude = 0;

void setup() {
  size(800, 800);
  // Cargar el archivo generado
  table = loadTable("procesado.csv", "header");
  background(5);
  frameRate(60); // Ajustar según la densidad de datos
}

void draw() {
  // Efecto de persistencia (Motion Blur)
  noStroke();
  fill(5, 20); 
  rect(0, 0, width, height);

  if (currentRow < table.getRowCount()) {
    // Leer el dato normalizado (0-100)
    amplitude = table.getFloat(currentRow, "valor_normalizado");

    pushMatrix();
    translate(width/2, height/2);
    
    // Configuración estética basada en el dato
    float radius = map(amplitude, 0, 100, 50, 350);
    int particles = (int)map(amplitude, 0, 100, 5, 50);
    float colorVal = map(amplitude, 0, 100, 0, 255);
    
    // Dibujar corona de partículas
    for (int i = 0; i < particles; i++) {
      float angle = random(TWO_PI);
      float x = cos(angle) * radius;
      float y = sin(angle) * radius;
      
      // El color vira de cian (frío/bajo) a magenta (caliente/alto)
      stroke(colorVal, 255 - colorVal, 255);
      strokeWeight(random(1, 4));
      point(x, y);
      
      // Líneas conectoras sutiles
      if (amplitude > 80) {
        stroke(255, colorVal, 0, 50);
        line(0, 0, x, y);
      }
    }
    popMatrix();

    currentRow++;
  } else {
    // Reiniciar visualización al terminar los datos
    currentRow = 0;
  }
}

