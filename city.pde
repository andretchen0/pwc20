float min_offset_between_buildings = 0.1;
float street_width = 1.0;
float block_width = 10;
int city_width = 120;
int city_depth = 120;

float g_camera_rot_z;
float g_camera_rot_x;

int max_buildings = 50;
float[][] buildings = new float[max_buildings][];
PImage[] buildings_textures = new PImage[max_buildings];
float[] buildings_x = new float[max_buildings];
float[] buildings_y = new float[max_buildings];
float[] buildings_w = new float[max_buildings];
float[] buildings_h = new float[max_buildings];
float[] buildings_d = new float[max_buildings];

PGraphics texture_context;

float FLOOR_HEIGHT_METERS = 3;
int PIXELS_PER_METER = 20;

int vertices_per_face = 4;
int coords_per_vertex = 5;
int coords_per_face = vertices_per_face * coords_per_vertex;

// NOTE:(important) 
// Assumes all faces are quads,
// All vertices are triplets

float[] cube = {-0.5, -0.5, 1.0, 0.0, 1.0, // Left 
                 0.5, -0.5, 1.0, 1.0, 1.0,
                 0.5, -0.5, 0.0, 1.0, 0.0,
                -0.5, -0.5, 0.0, 0.0, 0.0,
                -0.5, -0.5, 1.0, 1.0, 1.0, // Back
                -0.5,  0.5, 1.0, 2.0, 1.0,
                -0.5,  0.5, 0.0, 2.0, 0.0,
                -0.5, -0.5, 0.0, 1.0, 0.0,
                -0.5,  0.5, 1.0, 2.0, 1.0, // Right
                -0.5,  0.5, 0.0, 2.0, 0.0,
                 0.5,  0.5, 0.0, 3.0, 0.0,
                 0.5,  0.5, 1.0, 3.0, 1.0,
                 0.5,  0.5, 1.0, 4.0, 1.0, // Front
                 0.5, -0.5, 1.0, 3.0, 1.0,
                 0.5, -0.5, 0.0, 3.0, 0.0,
                 0.5,  0.5, 0.0, 4.0, 0.0,
                 0.5,  0.5, 1.0, 0.0, 0.0, // Top
                -0.5,  0.5, 1.0, 1.0, 0.0,
                -0.5, -0.5, 1.0, 1.0, 0.0,
                 0.5, -0.5, 1.0, 0.0, 0.0,
                 0.5,  0.5, 0.0, 0.0, 0.0, // Bottom
                -0.5,  0.5, 0.0, 1.0, 0.0,
                -0.5, -0.5, 0.0, 1.0, 0.0,
                 0.5, -0.5, 0.0, 0.0, 0.0}; 
                 
float[] pyramid = {-0.5,  -0.5, 0.0, 0.0, 0.0, // Left 
                   -0.25, -0.1, 1.0, 0.0, 0.0,
                   -0.25,  0.1, 1.0, 0.0, 0.0,
                   -0.5,   0.5, 0.0, 0.0, 0.0,
                   -0.5,   0.5, 0.0, 0.0, 0.0, // Up 
                   -0.25,  0.1, 1.0, 0.0, 0.0,
                    0.25,  0.1, 1.0, 0.0, 0.0,
                    0.5,   0.5, 0.0, 0.0, 0.0,
                    0.5,   0.5, 0.0, 0.0, 0.0, // Right
                    0.25,  0.1, 1.0, 0.0, 0.0,
                    0.25, -0.1, 1.0, 0.0, 0.0,
                    0.5,  -0.5, 0.0, 0.0, 0.0,
                    0.5,  -0.5, 0.0, 0.0, 0.0, // Down
                    0.25, -0.1, 1.0, 0.0, 0.0,
                   -0.25, -0.1, 1.0, 0.0, 0.0,
                   -0.5,  -0.5, 0.0, 0.0, 0.0,
                   -0.25,  0.1, 1.0, 0.0, 0.0, // Top
                   -0.25, -0.1, 1.0, 0.0, 0.0,
                    0.25, -0.1, 1.0, 0.0, 0.0,
                    0.25,  0.1, 1.0, 0.0, 0.0};

float[] scale(float[] points, float scale_x, float scale_y, float scale_z) {
  int points_length = points.length;
  float[] result = points.clone();
  if (scale_x != 0) {
    for (int i = 0; i < points_length; i += coords_per_vertex) {
      result[i] *= scale_x;
    }
  }
  if (scale_y != 0) {
    for (int i = 1; i < points_length; i += coords_per_vertex) {
      result[i] *= scale_y;
    }
  }
  if (scale_z != 0) {
    for (int i = 2; i < points_length; i += coords_per_vertex) {
      result[i] *= scale_z;
      result[i+2] = result[i];
    }
  }
  
  //IMPORTANT: only valid for vertical faces of rectangles
  int texture_u_offset = 0;
  int num_faces = points.length / (coords_per_vertex * vertices_per_face);
  for (int face = 0; face < num_faces; face ++) {
    float min_x = Integer.MAX_VALUE;
    float max_x = Integer.MIN_VALUE;
    float min_y = Integer.MAX_VALUE;
    float max_y = Integer.MIN_VALUE;
    for (int vertex = 0; vertex < vertices_per_face; vertex ++) {
      int point = face * coords_per_vertex * vertices_per_face + vertex * coords_per_vertex;
      if (points[point] < min_x) min_x = points[point];
      if (points[point] > max_x) max_x = points[point];
      if (points[point+1] < min_y) min_y = points[point+1];
      if (points[point+1] > max_y) max_y = points[point+1];
    }
    float distance = dist(min_x, min_y, max_x, max_y);
    for (int vertex = 0; vertex < vertices_per_face; vertex ++) {
      int point = face * coords_per_vertex * vertices_per_face + vertex * coords_per_vertex;
      if (points[point] == min_x && min_x != max_x) points[point+3] = texture_u_offset;
      if (points[point] == max_x && min_x != max_x) points[point+3] = texture_u_offset + distance;
      if (points[point+1] == min_y && min_y != max_y) points[point+3] = texture_u_offset;
      if (points[point+1] == max_y && min_y != max_y) points[point+3] = texture_u_offset + distance;
    }
    texture_u_offset += distance;
  }
  
  return result; 
}

float[] scaleX(float[] points, float scale_amount){
  return scale(points, scale_amount, 0, 0);
}

float[] scaleY(float[] points, float scale_amount){
  return scale(points, 0, scale_amount, 0);
}

float[] scaleZ(float[] points, float scale_amount){
  return scale(points, 0, 0, scale_amount);
}

float[] translate(float[] points, float x, float y, float z){
  int points_length = points.length;
  float[] result = points.clone();
  for (int i=0; i < points_length; i+= 5) {
    result[i] += x;
  }
  for (int i=1; i < points_length; i+= 5) {
    result[i] += y;
  }
  for (int i=2; i < points_length; i+= 5) {
    result[i] += z;
  }
  return result; 
}


float[] joinArrays(float[] a, float[] b) {
  float[] r = new float[a.length + b.length];
  System.arraycopy(a, 0, r, 0, a.length);
  System.arraycopy(b, 0, r, a.length, b.length);  
  return r;
}

color getNewWindowColor() {
  boolean lights_are_on = random(1) < 0.4;
  if (lights_are_on) return color(random(125) + 130);
  return color(random(25));
}

PImage getTexture(int w_px, int d_px, int h_px) {
  float w_meters = w_px / PIXELS_PER_METER;
  float d_meters = d_px / PIXELS_PER_METER;
  float h_meters = h_px / PIXELS_PER_METER;
  int window_width = ceil(random(w_meters));
  int num_floors = ceil(h_meters / FLOOR_HEIGHT_METERS);
  int num_windows_w = ceil(w_meters / window_width);
  int num_windows_d = ceil(d_meters / window_width);
  float window_h_to_floor_h_ratio = random(1) < 0.5 ? 1.0 : random(0.3) + 0.5;
  int texture_w_px = ceil(w_px * 2 + d_px * 2);
  int texture_h_px = ceil(h_px);
  if (texture_context.width < texture_w_px ||
      texture_context.height < texture_h_px) {
    texture_context = createGraphics(ceil(texture_w_px), ceil(texture_h_px));
  }
  texture_context.beginDraw();
  texture_context.background(0);

  boolean is_width_face = false;
  color last_color = getNewWindowColor();
  color first_color = getNewWindowColor();
  color curr_color = getNewWindowColor();
  noiseSeed((int)random(Integer.MAX_VALUE));

    for (int h = 0; h < num_floors; h++) {
      float w_offset = 0;


      for (int face = 0; face < 4; face++) {
        is_width_face = face % 2 == 0;
        if (face > 0) {
          w_offset = w_px;  
        }
        if (face > 1) {
          w_offset += d_px;
        }
        if (face > 2) {
          w_offset += w_px;  
        }

      int num_windows = is_width_face ? num_windows_w : num_windows_d;
      num_windows = num_windows < 1 ? 1 : num_windows;
      float window_w_px = is_width_face ? w_px / num_windows : d_px / num_windows;
      float window_h_px = FLOOR_HEIGHT_METERS * PIXELS_PER_METER;

      for (int w = 0; w < num_windows; w++) {
        boolean is_first_window_on_face = w == 0;
        boolean is_last_window_on_face = w == num_windows - 1;
        if (is_first_window_on_face && face == 0) {
          first_color = getNewWindowColor();
          curr_color = first_color;
        } else if (is_first_window_on_face) {
          curr_color = last_color;
        }
         else if (is_last_window_on_face && face == 3) {
           curr_color = first_color;
         } else if (is_last_window_on_face) {
           curr_color = last_color;
         } else {
           if (random(1) < 0.4) {
             curr_color = getNewWindowColor();
           } else {
             curr_color = last_color; 
           }
         }
         texture_context.pushMatrix();

         last_color = curr_color;
         texture_context.fill(curr_color);
         texture_context.stroke(0);
         texture_context.translate(w_offset + w * window_w_px, h * FLOOR_HEIGHT_METERS * PIXELS_PER_METER);
         texture_context.rect(0, 0, window_w_px, window_h_px * window_h_to_floor_h_ratio);
         texture_context.popMatrix();
      }
      texture_context.stroke(255);
      texture_context.line(w_offset, 0, w_offset, texture_context.height);
  }
  }
  texture_context.blendMode(SCREEN);
  setGradient(texture_context, 0, 0, texture_w_px, texture_h_px, #FFFFFF, #000000, 1);
  
  texture_context.filter(BLUR, 2);
  texture_context.endDraw();
  return texture_context.get(0, 0, texture_w_px, texture_h_px);
}


void setGradient(PGraphics context, int x, int y, float w, float h, color c1, color c2, int axis ) {
  noFill();
  if (axis == 1) {  // Top to bottom gradient
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      context.stroke(c);
      context.line(x, i, x+w, i);
    }
  }
  else if (axis == 0) {  // Left to right gradient
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      color c = lerpColor(c1, c2, inter);
      context.stroke(c);
      context.line(i, y, i, y+h);
    }
  }
}

void setup() {
  size(512, 512, P3D);

  texture_context = createGraphics(1, 1);

  for (int i = 0; i < max_buildings; i++) {
    int building_w = floor(random(10) + 10) * PIXELS_PER_METER;
    int building_d = floor(random(10) + 10) * PIXELS_PER_METER;
    int building_h = floor(random(100) + 4) * PIXELS_PER_METER;    
    
    buildings_textures[i] = getTexture(building_w, building_d, building_h);
    
    float[] body = scale(cube, building_w, building_d, building_h);
    float[] joined = body;
    
    float[] cap;
    
    if (random(1) < 0.2) {
      cap = translate(scale(body, 1.05, 1.05, 0.1), 0, 0, building_h);
    } else if (random(1) < 0.2) {
      cap = translate(scale(pyramid, building_w, building_d, 0.1 * building_h), 0, 0, building_h); 
    } else {
      cap = new float[0]; 
    }
    
    if (cap.length > 0) {
      float[] tmp = joinArrays(joined, cap);
      joined = tmp;
    }

    if (random(1.0) < 0.2) {
      float[] pedestal = scale(body, 1.1, 1.1, 0.1);
      float[] tmp = joinArrays(joined, pedestal);
      joined = tmp;
    }

    if (random(1.0) < 0.2) {
      float wings_height = random(0.5) + 0.3;
      float[] wing = translate(scale(body, 0.8, 0.8, wings_height), 1, 0, 0);
      float[] wing2 = translate(scale(body, 0.8, 0.8, wings_height), -1, 0, 0);
      float[] wings = joinArrays(wing, wing2);
      float[] tmp = joinArrays(joined, wings);
      joined = tmp;
    }

    buildings[i] = joined;
        
    float min_x = joined[0];
    float max_x = joined[0];
    float min_y = joined[1];
    float max_y = joined[1];
    float min_z = joined[2];
    float max_z = joined[2];
    
    for (int j = coords_per_vertex; j < joined.length; j += coords_per_vertex) {
      min_x = min_x < joined[j] ? min_x : joined[j];
      max_x = max_x > joined[j] ? max_x : joined[j];
      min_y = min_y < joined[j+1] ? min_y : joined[j+1];
      max_y = max_y > joined[j+1] ? max_y : joined[j+1];
      min_z = min_z < joined[j+2] ? min_z : joined[j+2];
      max_z = max_z > joined[j+2] ? max_z : joined[j+2];
    }
    
    buildings_w[i] = max_x - min_x;
    buildings_d[i] = max_y - min_y;
    buildings_h[i] = max_z - min_z;
    
    buildings_x[i] = (random(city_width) - city_width * 0.5) * PIXELS_PER_METER;
    buildings_y[i] = (random(city_depth) - city_depth * 0.5) * PIXELS_PER_METER;
  }
}

void draw() {
  //update();
  render();
}

void render() {
  background(0);

  pushMatrix();
  rotateX(PI/2);

  translate(width*0.5, -height*0.5, -400);
  stroke(0);
  strokeWeight(4.0);
  scale(0.25);
  
  rotateX(-g_camera_rot_x);
  rotateZ(-g_camera_rot_z); 
  
  for (int i = 0; i < max_buildings; i++) {
    pushMatrix();
    float x = buildings_x[i];
    float y = buildings_y[i];
    color tint_color = lerpColor(color(50, 200, 255), color(255, 200, 50), noise(x * 0.001, y * 0.001));

    translate(buildings_x[i], buildings_y[i]);
    float[] building = buildings[i];
    int building_length = building.length;   
   
    for (int v = 0; v < building_length; v += coords_per_vertex) {
      if (v % coords_per_face == 0) { 
        beginShape(); 
        tint(tint_color);  
        texture(buildings_textures[i]);
      }
      vertex(building[v], building[v + 1], building[v + 2],  building[v + 3],  building[v + 4]);
      if ((v+coords_per_vertex) % coords_per_face == 0) endShape();
    }
    popMatrix();
  } 
  popMatrix();
  
  g_camera_rot_z = 1.0 * mouseX/width * 2 * PI;
  g_camera_rot_x = 1.0 * mouseY/height;
}