#version 330 core
in vec3 vertexColor;
out vec4 FragColor;

uniform vec4 ownColor;

void main() {
  FragColor = ownColor;
}
