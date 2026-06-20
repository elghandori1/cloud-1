.PHONY: deploy ping check

deploy:
	ansible-playbook playbook.yml

ping:
	ansible cloud1 -m ping

check:
	ansible-playbook playbook.yml --check
