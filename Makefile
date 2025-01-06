.PHONY: site serve 

# Clean build.
site:
	rm -rf public
	zola build --drafts

serve:
	zola serve --drafts
