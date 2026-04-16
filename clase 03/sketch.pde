// ============================================================
//  GPS Tracker Visualizer
//  Datos: Location_transformed.csv
//  Columnas usadas: time_epoch, latitude, longitude
//  latitude y longitude están normalizadas en rango 0–100
// ============================================================

// --- Tabla de datos ---
Table datos;           // Objeto que almacena el CSV completo
int totalPuntos;       // Número total de filas (puntos GPS)

// --- Animación ---
int indiceActual = 0;  // Punto GPS que se está dibujando ahora
int velocidad    = 5;  // Cuántos puntos se avanzan por frame (aumenta para ir más rápido)
boolean pausado  = false; // Estado de pausa (tecla ESPACIO)

// --- Apariencia ---
float margen = 40;     // Margen en píxeles alrededor del canvas

// --- Rastro (trail) ---
int maxRastro = 200;   // Cuántos puntos pasados se muestran con desvanecimiento
// ArrayDeque no existe en Processing, usamos un arreglo circular:
float[] rastroX;       // Coordenadas X del rastro
float[] rastroY;       // Coordenadas Y del rastro
int cabezaRastro = 0;  // Índice de escritura en el arreglo circular
int tamRastro    = 0;  // Cuántos puntos hay en el rastro actualmente

// ============================================================
//  setup() — se ejecuta UNA sola vez al iniciar el sketch
// ============================================================
void setup() {
  size(800, 800);            // Tamaño de la ventana en píxeles
  colorMode(RGB, 255);       // Modo de color estándar RGB
  smooth();                  // Activa anti-aliasing para bordes suaves

  // Carga el archivo CSV desde la carpeta "data/" del sketch
  // → Crea una carpeta llamada "data" junto al .pde y coloca el CSV ahí
  datos = loadTable("Location_transformed.csv", "header");
  totalPuntos = datos.getRowCount(); // Total de filas leídas

  // Inicializa los arreglos del rastro con tamaño máximo
  rastroX = new float[maxRastro];
  rastroY = new float[maxRastro];

  println("Puntos cargados: " + totalPuntos); // Imprime en consola para verificar
  frameRate(60);             // 60 fotogramas por segundo
}

// ============================================================
//  draw() — se ejecuta en BUCLE (una vez por frame)
// ============================================================
void draw() {
  // Fondo oscuro semitransparente: crea efecto de desvanecimiento del rastro antiguo
  // El valor alpha (15) controla qué tan rápido se desvanece: menor = más lento
  fill(10, 10, 20, 15);
  noStroke();
  rect(0, 0, width, height); // Rectángulo cubre toda la pantalla con transparencia

  // Dibuja el rastro de puntos anteriores con opacidad decreciente
  dibujarRastro();

  // Avanza la animación si no está pausada
  if (!pausado && indiceActual < totalPuntos) {
    for (int i = 0; i < velocidad; i++) {     // Avanza varios puntos por frame
      if (indiceActual < totalPuntos) {
        procesarPunto(indiceActual);           // Procesa y guarda el punto actual
        indiceActual++;
      }
    }
  }

  // Dibuja el punto "cabeza" (posición actual) con un destello
  dibujarCabeza();

  // Dibuja la interfaz de texto (HUD) encima de todo
  dibujarHUD();
}

// ============================================================
//  procesarPunto() — lee un punto del CSV y lo agrega al rastro
// ============================================================
void procesarPunto(int idx) {
  TableRow fila = datos.getRow(idx); // Lee la fila número idx del CSV

  // Lee los valores crudos de latitud y longitud (ya en rango 0–100)
  float lat = fila.getFloat("latitude");
  float lon = fila.getFloat("longitude");

  // Convierte de rango 0–100 al espacio del canvas en píxeles
  // map(valor, desde_min, desde_max, hasta_min, hasta_max)
  // Nota: latitud se invierte (height - margen → margen) porque en pantalla
  // el eje Y crece hacia abajo, pero en geografía crece hacia arriba
  float x = map(lon, 0, 100, margen, width  - margen);
  float y = map(lat, 0, 100, height - margen, margen); // Invertido

  // Guarda el punto en el arreglo circular del rastro
  rastroX[cabezaRastro] = x;
  rastroY[cabezaRastro] = y;

  // Avanza el puntero circular (vuelve a 0 al llegar al final)
  cabezaRastro = (cabezaRastro + 1) % maxRastro;

  // Incrementa el tamaño real del rastro hasta el máximo
  if (tamRastro < maxRastro) tamRastro++;
}

// ============================================================
//  dibujarRastro() — dibuja los puntos anteriores con fade-out
// ============================================================
void dibujarRastro() {
  for (int i = 0; i < tamRastro - 1; i++) {
    // Calcula el índice real en el arreglo circular
    int idxA = (cabezaRastro - tamRastro + i     + maxRastro * 2) % maxRastro;
    int idxB = (cabezaRastro - tamRastro + i + 1 + maxRastro * 2) % maxRastro;

    // Opacidad proporcional a la posición en el rastro:
    // los más viejos son casi transparentes, los recientes son más opacos
    float alpha = map(i, 0, tamRastro, 10, 200);

    // Gradiente de color: azul para puntos viejos, cian para recientes
    float r = map(i, 0, tamRastro,  0,  50);
    float g = map(i, 0, tamRastro, 80, 220);
    float b = map(i, 0, tamRastro, 200, 255);

    stroke(r, g, b, alpha); // Color del trazo con transparencia
    strokeWeight(1.2);       // Grosor de la línea del rastro
    line(rastroX[idxA], rastroY[idxA], rastroX[idxB], rastroY[idxB]); // Línea entre puntos consecutivos
  }
}

// ============================================================
//  dibujarCabeza() — dibuja el punto actual con un halo
// ============================================================
void dibujarCabeza() {
  if (tamRastro == 0) return; // Nada que dibujar todavía

  // Obtiene las coordenadas del último punto guardado
  int idxUltimo = (cabezaRastro - 1 + maxRastro) % maxRastro;
  float cx = rastroX[idxUltimo];
  float cy = rastroY[idxUltimo];

  // Halo exterior pulsante usando sin() del tiempo → efecto latido
  float pulso = map(sin(frameCount * 0.1), -1, 1, 6, 14);
  noFill();
  stroke(0, 255, 200, 60);   // Color verde-cian semitransparente
  strokeWeight(1.5);
  ellipse(cx, cy, pulso * 2, pulso * 2); // Círculo exterior pulsante

  // Punto central sólido (la posición GPS real)
  noStroke();
  fill(0, 255, 180);          // Verde-cian brillante
  ellipse(cx, cy, 7, 7);      // Círculo de 7px de diámetro
}

// ============================================================
//  dibujarHUD() — interfaz de texto encima del canvas
// ============================================================
void dibujarHUD() {
  // Progreso de la animación como porcentaje
  float pct = map(indiceActual, 0, totalPuntos, 0, 100);

  // Barra de progreso en la parte inferior
  float barW = width - margen * 2; // Ancho total de la barra
  float barH = 4;                  // Alto de la barra en píxeles
  float barY = height - margen / 2;

  noStroke();
  fill(255, 255, 255, 30);    // Fondo de la barra (gris translúcido)
  rect(margen, barY, barW, barH, 2);

  fill(0, 220, 180);          // Relleno de progreso (verde-cian)
  rect(margen, barY, barW * pct / 100.0, barH, 2);

  // Textos informativos
  fill(180, 255, 220);        // Color del texto (verde claro)
  textSize(11);
  textAlign(LEFT, TOP);
  text("GPS TRACKER", margen, margen - 28);  // Título

  textSize(10);
  fill(120, 200, 180);        // Color secundario para datos
  text("Puntos: " + indiceActual + " / " + totalPuntos, margen, margen - 14);
  text(int(pct) + "%", width - margen - 30, margen - 14);

  // Mensaje de pausa si está pausado
  if (pausado) {
    fill(255, 220, 0, 200);   // Amarillo para aviso de pausa
    textSize(13);
    textAlign(CENTER, CENTER);
    text("[ PAUSADO — presiona ESPACIO para continuar ]", width / 2, height / 2);
  }

  // Instrucciones en la esquina inferior derecha
  fill(80, 120, 110);
  textSize(9);
  textAlign(RIGHT, BOTTOM);
  text("ESPACIO: pausa  |  R: reiniciar  |  ↑↓: velocidad", width - margen, height - margen / 2 - 10);
}

// ============================================================
//  keyPressed() — responde a teclas del teclado
// ============================================================
void keyPressed() {
  if (key == ' ') {
    pausado = !pausado;        // Alterna pausa / reproducción
  }

  if (key == 'r' || key == 'R') {
    // Reinicia la animación desde el principio
    indiceActual = 0;
    cabezaRastro = 0;
    tamRastro    = 0;
    background(10, 10, 20);   // Limpia la pantalla
  }

  if (keyCode == UP) {
    velocidad = min(velocidad + 1, 50); // Aumenta velocidad (máximo 50)
    println("Velocidad: " + velocidad);
  }

  if (keyCode == DOWN) {
    velocidad = max(velocidad - 1, 1);  // Reduce velocidad (mínimo 1)
    println("Velocidad: " + velocidad);
  }
}
