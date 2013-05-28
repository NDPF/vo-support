.PHONY: true

test:
	./runtests.sh

NOTES.pdf: NOTES.org
	emacs -q --batch NOTES.org -f org-export-as-pdf

