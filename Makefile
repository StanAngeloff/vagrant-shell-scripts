BIN_PATH    := $(CURDIR)/bin
VENDOR_PATH := $(CURDIR)/vendor

.PHONY: default install-ruby-dependencies vagrant-provision install clean test

default:
	@echo "No default $(MAKE) target configured."
	@exit 1

required-dependency =                                           \
	echo -n "Checking if '$(1)' is available... " ;               \
	$(eval COMMAND := which '$(1)')                               \
	if $(COMMAND) >/dev/null; then                                \
		$(COMMAND) ;                                                \
	else                                                          \
		echo "fail:" ;                                              \
		echo ;                                                      \
		echo "    $(COMMAND)" ;                                     \
		echo ;                                                      \
		echo "You must install '$(2)' before you could continue." ; \
		exit 1;                                                     \
	fi

install-ruby-gem-if-missing =                                                                      \
	echo -n "Checking if '$(1)' RubyGem is available... " ;                                          \
	$(eval GEM_VERSION := ruby -rubygems -e "puts Gem::Specification::find_by_name('$(1)').version") \
	if $(GEM_VERSION) 1>/dev/null 2>&1; then                                                         \
		$(GEM_VERSION) ;                                                                               \
	else                                                                                             \
		$(eval COMMAND_INSTALL := gem install --remote --no-ri --no-rdoc '$(1)')                       \
		echo "nope." ;                                                                                 \
		echo -n "Installing '$(1)' RubyGem... " ;                                                      \
		$(COMMAND_INSTALL) 1>/dev/null ;                                                               \
		$(GEM_VERSION) ;                                                                               \
	fi

install-ruby-dependencies: $(VENDOR_PATH)/ruby
$(VENDOR_PATH)/ruby:
	@$(call required-dependency,ruby,Ruby)
	@$(call required-dependency,gem,RubyGems)
	@$(call install-ruby-gem-if-missing,bundler)
	@$(call required-dependency,bundle,Bundler)
	@echo -n 'Installing RubyGem dependencies... '
	@bundle install --path '$(VENDOR_PATH)' --binstubs '$(BIN_PATH)' 1>/dev/null
	@echo 'OK'

vagrant-provision: install-ruby-dependencies $(CURDIR)/.vagrant
$(CURDIR)/.vagrant:
	@'$(BIN_PATH)/vagrant' up

install: vagrant-provision

clean:
	@if [ -f '$(CURDIR)/.vagrant' ]; then     \
		'$(BIN_PATH)/vagrant' destroy --force ; \
		rm '$(CURDIR)/.vagrant'  ;              \
	fi
	@if [ -d '$(VENDOR_PATH)/ruby' ]; then \
		rm -Rf '$(VENDOR_PATH)/ruby'* ;      \
	fi
	@for file in bin/*; do                                                      \
		grep "$$( basename "$$file" )" bin/.gitignore >/dev/null || rm "$$file" ; \
	done

test: install
	@for file in test/*-test.sh; do                                              \
		'$(BIN_PATH)/vagrant' ssh -c '( cd /vagrant && bin/roundup '"$$file"' )' ; \
	done


# vim: ts=2 sw=2 noet
