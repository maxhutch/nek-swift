all:
	$(eval TMP := $(shell pwd))
	sed 's:@pwd:${TMP}:' < local.conf > local_cfg.conf
	sed 's:@pwd:${TMP}:' < nek.swift > nek_cfg.swift

