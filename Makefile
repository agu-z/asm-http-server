run: Server
	./Server

Server: Server.o
	ld -macosx_version_min 12.0.0 -o Server Server.o -lSystem -syslibroot \
		`xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64 

Server.o: Server.s
	as -o Server.o Server.s

