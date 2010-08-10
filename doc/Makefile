all: service.html

service.html: service.txt
	python -c 'import textile, sys; filename=sys.argv[1]; infile=open(filename, "r"); contents=infile.read(); print textile.textile(contents)' $< > $@

clean:
	rm service.html
