package main
import "core:fmt"
import "core:math"
import "core:math/rand"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"


main :: proc() {
	// Init GLFW
	init := glfw.Init()
	if !init {
		fmt.println("what happened")
	}

	defer glfw.Terminate()

	// Set to OpenGL 3.3 core profile
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	//Create Window with GLFW 
	windowHandle: glfw.WindowHandle = glfw.CreateWindow(1280, 720, "Hello Quad in odin", nil, nil)

	if windowHandle == nil {
		fmt.println("Failed to create a window")
	}

	// Set current opengl context to window
	glfw.MakeContextCurrent(windowHandle)

	// vsync?
	glfw.SwapInterval(0)

	glfw.SetFramebufferSizeCallback(windowHandle, frameBufferSizeCallback)

	// only load opengl functions upto major.minor profile ????
	gl.load_up_to(3, 3, proc(p: rawptr, name: cstring) {
		(^rawptr)(p)^ = glfw.GetProcAddress(name)
	})

	gl.Viewport(0, 0, 1280, 720)
	glfw.SetFramebufferSizeCallback(windowHandle, frameBufferSizeCallback)
	glfw.SetWindowSizeCallback(windowHandle, frameBufferSizeCallback)


	vertexShaderId, ok := gl.compile_shader_from_source(vertexShader, gl.Shader_Type.VERTEX_SHADER)

	if (!ok) {
		fmt.println("Something wrong with vertex shader, fix it")
	}


	fragmentShaderId, ook := gl.compile_shader_from_source(
		fragmentShader,
		gl.Shader_Type.FRAGMENT_SHADER,
	)
	if (!ook) {
		fmt.println("Something wrong with vertex shader, fix it")
	}

	shaderProgram, success := gl.create_and_link_program([]u32{fragmentShaderId, vertexShaderId})
	if !success {
		fmt.println("Uh oh, your shader program sucks, fix it")
	}

	vertices := [?]f32 {
		// Positions    // Colors
		-0.5,
		-0.5,
		0.0,
		1.0,
		1.0,
		0.0, // Bottom left (Yellow)
		0.5,
		-0.5,
		0.0,
		0.0,
		1.0,
		1.0, // Bottom right (Cyan)
		0.5,
		0.5,
		0.0,
		1.0,
		0.0,
		1.0, // Top (Magenta)
		-0.5,
		0.5,
		0.0,
		1.0,
		0.0,
		1.0, // Top (Magenta)
		0.5,
		0.5,
		0.0,
		1.0,
		0.0,
		1.0, // Top (Magenta)
		-0.5,
		-0.5,
		0.0,
		1.0,
		1.0,
		0.0, // Bottom left (Yellow)
	}


	//Vertex array objects
	VAO: u32

	gl.GenVertexArrays(1, &VAO)
	gl.BindVertexArray(VAO)

	// Vertex buffer objects
	VBO: u32
	gl.GenBuffers(1, &VBO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 6, cast(uintptr)0)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	gl.UseProgram(shaderProgram)


	for (!glfw.WindowShouldClose(windowHandle)) {
		glfw.PollEvents()
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)

		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

		gl.UseProgram(shaderProgram)
		gameTime := glfw.GetTime()
		greenValue := cast(f32)(math.sin(gameTime) / 2) + 0.5

		location := gl.GetUniformLocation(shaderProgram, "frogColor")
		gl.Uniform4f(location, 0, greenValue, 0, 1)

		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
		glfw.SwapBuffers(windowHandle)
	}

}

frameBufferSizeCallback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

fragmentShader := `
#version 330 core
in vec3 vertexColor;
out vec4 FragColor;

uniform vec4 frogColor;

void main() {
  //FragColor = vec4(vertexColor, 1.0);
	FragColor = frogColor;
}
`

vertexShader := `#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;

out vec3 vertexColor;

void main() {
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	vertexColor = aColor;
}`