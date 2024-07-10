package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	// Program ID
	ID: u32,
}

loadShaderFromFile :: proc(vertexPath: string, fragmentPath: string) -> Shader {
	data: []byte
	ok: bool

	data, ok = os.read_entire_file_from_filename(vertexPath)
	if (!ok) {
		fmt.println("Failed loading vertex shader")
	}
	vertexCode, _ := strings.clone_to_cstring(string(data))
	fmt.println(vertexCode)

	data, ok = os.read_entire_file_from_filename(fragmentPath)
	fragmentCode, _ := strings.clone_to_cstring(string(data))
	if (!ok) {
		fmt.println("Failed loading fragment shader")
	}

	fmt.println(fragmentCode)

	vertex, fragment: u32
	success: i32
	infoLog: [^]u8

	vertex = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex, 1, &vertexCode, nil)
	gl.CompileShader(vertex)

	gl.GetShaderiv(vertex, gl.COMPILE_STATUS, &success)
	if (success == 0) {
		gl.GetShaderInfoLog(vertex, 512, nil, infoLog)
		fmt.eprintln("Failure to compile vertex shader", infoLog)
	}

	fragment = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment, 1, &fragmentCode, nil)
	gl.CompileShader(fragment)

	gl.GetShaderiv(fragment, gl.COMPILE_STATUS, &success)
	if (success == 0) {
		gl.GetShaderInfoLog(vertex, 512, nil, infoLog)
		fmt.eprintln("Failure to compile fragment shader", infoLog)
	}

	ID := gl.CreateProgram()
	gl.AttachShader(ID, vertex)
	gl.AttachShader(ID, fragment)
	gl.LinkProgram(ID)

	gl.GetProgramiv(fragment, gl.COMPILE_STATUS, &success)
	if (success == 0) {
		fmt.eprintln("Failure to compile fragment shader")
	}
	gl.DeleteShader(vertex)
	gl.DeleteShader(fragment)

	shader := Shader {
		ID = ID,
	}
	return shader

}
