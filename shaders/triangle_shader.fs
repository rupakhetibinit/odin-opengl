#version 330 core

in vec3 vertexColor;
in vec4 vertexPosition;
out vec4 FragColor;

uniform vec4 ownColor;

void main() {
  FragColor = vertexPosition+ownColor;
}
