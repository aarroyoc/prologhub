build:
	rm -rf output
	scryer-prolog main.pl

get-deps:
	rm -rf teruel
	git clone --depth 1 --branch v1.1.0 https://github.com/aarroyoc/teruel

sync:
        rsync -avh output/ /data/webs/prologhub-output 
