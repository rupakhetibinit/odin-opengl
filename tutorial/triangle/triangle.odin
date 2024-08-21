package main
import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 1366
HEIGHT :: 768

main :: proc() {
	if !glfw.Init() {
		fmt.println("Failed to init glfw")
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(WIDTH, HEIGHT, "Hello window", nil, nil)
	defer glfw.DestroyWindow(window)

	if (window == nil) {
		fmt.println("Window failed")
		return
	}

	glfw.MakeContextCurrent(window)

	glfw.SwapInterval(0)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, WIDTH, HEIGHT)
	
	//odinfmt:disable
	vertices := [?]f32{
		0			,0.5		,0,
		-0.5	,-0.5		,0,
		0.5		,-0.5		,0
	}
	//odinfmt:enable

	colors := [?]f32{0, 1, 0, 1, 0, 0, 0, 0, 1}

	vbo_vertices: u32 = 0
	gl.GenBuffers(1, &vbo_vertices)

	vbo_colors: u32 = 0
	gl.GenBuffers(1, &vbo_colors)

	vao: u32 = 0
	gl.GenVertexArrays(1, &vao)

	program, ok := gl.load_shaders_file(
		"tutorial/triangle/triangle.vs",
		"tutorial/triangle/triangle.fs",
	)

	if (!ok) {
		fmt.println("failed to load shaders")
		return
	}


	for !glfw.WindowShouldClose(window) {
		processInput(&window)

		// Core Rendering Logic
		gl.ClearColor(0.2, 0.3, 0.4, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.BindBuffer(gl.ARRAY_BUFFER, vbo_vertices)
		gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
		gl.EnableVertexAttribArray(0)

		gl.BindBuffer(gl.ARRAY_BUFFER, vbo_colors)
		gl.BufferData(gl.ARRAY_BUFFER, size_of(colors), &colors, gl.STATIC_DRAW)
		gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
		gl.EnableVertexAttribArray(1)

		gl.UseProgram(program)
		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.PollEvents()
		glfw.SwapBuffers(window)
	}
}

processInput :: proc(window: ^glfw.WindowHandle) {
	if (glfw.GetKey(window^, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window^, true)
	}
}
