ROOT_REPO:=jupyter/all-spark-notebook:258e25c03cba
REPO:=caravel/dev-image:258e25c03cba

NODE_INSTALL=apt-get update && \
		apt-get install --yes curl && \
		curl --silent --location https://deb.nodesource.com/setup_0.12 | sudo bash - && \
		apt-get install --yes nodejs npm && \
		ln -s /usr/bin/nodejs /usr/bin/node

DEV_SETUP=source activate python2 && \
		apt-get install --yes build-essential libssl-dev libffi-dev python-dev python-pip && \
		python setup.py develop && \
		fabmanager create-admin --app caravel && \
		caravel db upgrade && \
		caravel init && \
		caravel load_examples

init:
	@-docker rm -f dev-image-build
	@docker run -it --workdir /src --user root --name dev-image-build \
		-v `pwd`:/src \
		$(ROOT_REPO) bash -c '$(NODE_INSTALL) && $(DEV_SETUP)'
	@docker commit dev-image-build $(REPO)
	@-docker rm -f dev-image-build

caravel/assets/node_modules: caravel/assets/package.json
	cd caravel/assets; npm install

dev: caravel/assets/node_modules
	@docker run -it --rm --workdir /src --user root\
		-v `pwd`:/src \
		-p 8081:8081 \
		$(REPO) \
		bash -c 'source activate python2 && caravel runserver -d -p 8081 && (cd caravel/assets; npm run dev)'
