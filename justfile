build:
	rm -rf output
	/home/aarroyoc/dev/scryer-prolog/target/release/scryer-prolog main.pl

get-deps:
	rm -rf teruel
	git clone --depth 1 --branch v1.1.0 https://github.com/aarroyoc/teruel

sync:
        rsync -avh output/ /var/data/prologhub-output 
