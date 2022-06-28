$(shell mkdir -p out)

run: out/server
	out/server

debug: out/server
	lldb out/server

out/server: out/server.o
	ld -macosx_version_min 12.0.0 -o out/server out/server.o -lSystem -syslibroot \
		`xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64 

out/server.o: server.s out/const.s
	as -g -o out/server.o server.s

out/const.s: out/make_const
	out/make_const

out/make_const: make_const.c
	cc $< -o $@

