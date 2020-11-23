.PHONY: build up clean

clean:
	docker rmi alpine-dropbear || :
	ssh-keygen -R '[localhost]:4834'

build:
	docker build -t alpine-dropbear .

up:
	docker run -it --rm -p 4834:22 alpine-dropbear
