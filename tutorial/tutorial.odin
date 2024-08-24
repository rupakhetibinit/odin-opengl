package main
import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 1366
HEIGHT :: 768
MAX_VERTICES :: 10000
FLOATS_PER_VERTEX :: 6 // 3 position + 3 colors

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

	glfw.SetFramebufferSizeCallback(window, frameBufferSizeCallback)

	batch := init_batch()

	for !glfw.WindowShouldClose(window) {

		processInput(&window)

		gl.ClearColor(0.2, 0.3, 0.4, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


		// draw_triangle(&batch, -0.5, -0.5, 0.5, -0.5, 0.0, 0.5, 1.0, 0.0, 0.0)
		draw_rectangle(&batch, {200, 200}, 400, 200, {0.5, 1.0, 0.0})

		flush(&batch)

		glfw.PollEvents()
		glfw.SwapBuffers(window)
	}
}

processInput :: proc(window: ^glfw.WindowHandle) {
	if (glfw.GetKey(window^, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window^, true)
	}
}

frameBufferSizeCallback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

PrimitiveType :: enum {
	Triangles,
	Quads,
	Lines,
}

Vertex :: struct {
	x, y, z: f32,
	r, g, b: f32,
}

BatchRenderer :: struct {
	vbo, vao:          u32,
	shader_program:    u32,
	vertices:          [MAX_VERTICES]Vertex,
	vertex_count:      int,
	current_primitive: PrimitiveType,
}

init_batch :: proc() -> BatchRenderer {
	batch: BatchRenderer

	gl.GenVertexArrays(1, &batch.vao)
	gl.BindVertexArray(batch.vao)


	gl.GenBuffers(1, &batch.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)


	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)


	triangle_shader, ok := gl.load_shaders_file(
		"tutorial/triangle/triangle.vs",
		"tutorial/triangle/triangle.fs",
	)

	if !ok {
		fmt.println("Error while loading triangle program")
		return BatchRenderer{}
	}

	batch.shader_program = triangle_shader
	batch.current_primitive = .Triangles

	check_gl_error("init_batch")

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	return batch
}

begin_drawing :: proc(batch: ^BatchRenderer, primitive: PrimitiveType) {
	if (batch.vertex_count > 0 && batch.current_primitive != primitive) {
		flush(batch)
	}
	batch.current_primitive = primitive
}

add_vertex :: proc(batch: ^BatchRenderer, x, y, z, r, g, b: f32) {
	if batch.vertex_count >= MAX_VERTICES {
		flush(batch)
	}
	vertex := Vertex{x, y, z, r, g, b}
	batch.vertices[batch.vertex_count] = vertex
	batch.vertex_count += 1
}

draw_triangle :: proc(batch: ^BatchRenderer, x1, y1, x2, y2, x3, y3, r, g, b: f32) {
	begin_drawing(batch, .Triangles)
	add_vertex(batch, x1, y1, 0, r, g, b)
	add_vertex(batch, x2, y2, 0, r, g, b)
	add_vertex(batch, x3, y3, 0, r, g, b)
}

flush :: proc(batch: ^BatchRenderer) {
	if (batch.vertex_count == 0) {
		return
	}

	gl.UseProgram(batch.shader_program)
	gl.BindVertexArray(batch.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, batch.vbo)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		batch.vertex_count * size_of(Vertex),
		&batch.vertices[0],
		gl.DYNAMIC_DRAW,
	)

	// Update only the part of the buffer we're using
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, batch.vertex_count * size_of(Vertex), &batch.vertices[0])

	gl_primitive: u32
	vertices_per_primitive: int

	#partial switch batch.current_primitive {
	case .Triangles:
		gl_primitive = gl.TRIANGLES
		vertices_per_primitive = 3
	}

	gl.DrawArrays(gl_primitive, 0, i32(batch.vertex_count))

	batch.vertex_count = 0

}

check_gl_error :: proc(location: string) {
	for {
		err := gl.GetError()
		if err == gl.NO_ERROR {
			break
		}
		fmt.printf("OpenGL error at %s: %x\n", location, err)
	}
}

draw_rectangle :: proc(
	batch: ^BatchRenderer,
	position: Vector2,
	width: f32,
	height: f32,
	color: Color,
) {

	normalized_x := (position[0] / WIDTH) * 2 - 1
	normalized_y := (position[1] / HEIGHT) * 2 - 1
	normalized_width := (width / WIDTH) * 2
	normalized_height := (height / HEIGHT) * 2

	begin_drawing(batch, .Triangles)

	add_vertex(batch, normalized_x, normalized_y, 0, color.r, color.g, color.b)
	add_vertex(batch, normalized_x + normalized_width, normalized_y, 0, color.r, color.g, color.b)
	add_vertex(
		batch,
		normalized_x + normalized_width,
		normalized_y + normalized_height,
		0,
		color.r,
		color.g,
		color.b,
	)

	add_vertex(batch, normalized_x, normalized_y, 0, color.r, color.g, color.b)
	add_vertex(
		batch,
		normalized_x + normalized_width,
		normalized_y + normalized_height,
		0,
		color.r,
		color.g,
		color.b,
	)
	add_vertex(batch, normalized_x, normalized_y + normalized_height, 0, color.r, color.g, color.b)
}

Vector2 :: distinct [2]f32
Color :: distinct [3]f32
