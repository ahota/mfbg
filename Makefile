POST_DIR=posts
LAYOUT_DIR=layout
OUTPUT_DIR=site
BUILD_DIR=build

POSTS=$(notdir $(wildcard $(POST_DIR)/*.md))
POSTS_HTML=$(POSTS:%.md=$(OUTPUT_DIR)/%.html)

.PHONY: clean

all: $(POSTS_HTML) $(OUTPUT_DIR)/index.html

$(OUTPUT_DIR)/index.html: $(LAYOUT_DIR)/index_header.html $(LAYOUT_DIR)/index_footer.html $(POST_DIR)
	cp $(LAYOUT_DIR)/index_header.html $@
	for filename in `ls -t $(POST_DIR)`; do \
		f=$(POST_DIR)/$$filename; \
		echo "<a href=\"/$$(basename $$f .md).html\">`sed '3q;d' $$f` - `sed '1q;d' $$f`</a><br/>" >> $@; \
	done
	cat $(LAYOUT_DIR)/index_footer.html >> $@

$(OUTPUT_DIR)/%.html: $(BUILD_DIR)/%.html $(BUILD_DIR)/%_header.html $(LAYOUT_DIR)/footer.html | $(OUTPUT_DIR)
	cat $(BUILD_DIR)/$*_header.html $< $(LAYOUT_DIR)/footer.html > $@

$(BUILD_DIR)/%_header.html: $(POST_DIR)/%.md $(LAYOUT_DIR)/header.html
	sed "s/{title}/$(shell head -1 $<)/g" $(LAYOUT_DIR)/header.html > $@

$(BUILD_DIR)/%.html: $(POST_DIR)/%.md | $(BUILD_DIR)
	pandoc -f markdown+pipe_tables -t html --ascii $< > $@

$(OUTPUT_DIR):
	mkdir -p $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	@rm -rf $(OUTPUT_DIR) $(BUILD_DIR)

