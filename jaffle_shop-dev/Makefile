
DATE := $(shell date '+%+4Y-%m-%d')

help:
	@echo "Run 'make zip' to generate dbt metadata description."

$(DATE)_jaffle.zip: target/catalog.json target/manifest.json
	@zip $@ $^ && echo "...files compressed"

.PHONY: clean zip

zip: $(DATE)_jaffle.zip

clean:
	@rm -f $(DATE)_jaffle.zip && echo "...files cleaned up"
