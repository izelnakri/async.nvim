lint:
	echo "===> Linting"
	luacheck lua/ --globals vim

fmt:
	echo "===> Formatting"
	stylua lua/ --config-path=stylua.toml

test:
	echo "===> Testing"
	nvim --headless -c "PlenaryBustedDirectory tests/"
