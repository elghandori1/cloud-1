.PHONY: deploy ping check

deploy:
	ansible-playbook playbook.yml --ask-vault-pass

ping:
	ansible cloud1 -m ping

check:
	ansible-playbook playbook.yml --check --ask-vault-pass
