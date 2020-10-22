CMAKE = cmake
#Switch to activatad Build Type
# BUILD_TYPE=Debug
BUILD_TYPE=Release
# BUILD_TYPE=RelWithDebInfo
# BUILD_TYPE=MinSizeRel

RELEASE_DIR=./INSTALL_DIR

CMAKE_BUILD_DIR= build
compile_commands=$(CMAKE_BUILD_DIR)/compile_commands.json

APP_NAME=date-tz

# Switch to your prefered build tool.
BUILD_TOOL = "Unix Makefiles"
# BUILD_TOOL = "CodeBlocks - Unix Makefiles"
# BUILD_TOOL = "Eclipse CDT4 - Unix Makefiles"

# -DCMAKE_BUILD_TYPE=Debug -DCMAKE_ECLIPSE_GENERATE_SOURCE_PROJECT=TRUE -DCMAKE_ECLIPSE_MAKE_ARGUMENTS=-j3 -DCMAKE_ECLIPSE_VERSION=4.1

default: $(APP_NAME)

release:
	$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"  \
	-DBUILD_32=ON \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_INSTALL_PREFIX:PATH=$(RELEASE_DIR)
	$(MAKE) -C Release $(APP_NAME)

$(CMAKE_BUILD_DIR): generate_build_tool

$(APP_NAME): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_NAME)
##
## @brief DocTest
##
##
.PHONY: clean
clean:
	$(RM) -r tags
	$(RM) -r cscope.out
	cd $(CMAKE_BUILD_DIR) &&  $(MAKE) clean $(ARGS); cd ..
	# $(MAKE) -C $(CMAKE_BUILD_DIR) clean

$(APP_TEST): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_TEST)


build: generate_build_tool
	# $(CMAKE) --build $(CMAKE_BUILD_DIR)
	# $(MAKE) all

run: $(APP_NAME)
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) run
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	cd $(DAFUR_DIR) &&  ./$(APP_NAME) $(ARGS); cd ..
endif

gdb_run:
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) gdb_run
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	cd $(DAFUR_DIR) && tgdb --args $(APP_NAME) $(ARGS); cd ..
	# cd $(DAFUR_DIR) && gdb --args $(APP_NAME) $(ARGS); cd ..
endif

memcheck: $(APP_NAME)
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) memcheck
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	# cd $(DAFUR_DIR) && valgrind --leak-check=full  --track-origins=yes -v ./$(APP_NAME) $(ARGS); cd ..
	# cd $(DAFUR_DIR) && valgrind --leak-check=full -v ./$(APP_NAME) $(ARGS); cd ..
	cd $(DAFUR_DIR) && valgrind --leak-check=full --show-leak-kinds=all -v ./$(APP_NAME) $(ARGS); cd ..
endif

memcheck_test: $(APP_TEST)
	cd $(CMAKE_BUILD_DIR) &&  valgrind --leak-check=full -v ./$(APP_TEST); cd ..

cppcheck:
	cppcheck --project=build/compile_commands.json --enable=all
	# cppcheck $(INC_DIR) $(SRC_DIR)

# cppcheck: | $(compile_comands)
	# cd $(CMAKE_BUILD_DIR) && cppcheck --project=compile_commands.json; cd ..


compile_commands: $(compile_comands)

$(compile_commands): $(APP_NAME) | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_NAME)


generate_build_tool:
	$(CMAKE) -H. -B$(CMAKE_BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -G $(BUILD_TOOL) \
	-DBUILD_32=ON \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DBUILD_SHARED_LIBS=ON

install_global:|
	$(MAKE) $(APP_NAME)
	cd ${CMAKE_BUILD_DIR} && sudo $(MAKE) install && cd ..

install_release: distclean release
	mkdir -p $(RELEASE_DIR)
	cd Release && $(MAKE) install && cd ..


tags: | $(CMAKE_BUILD_DIR)
	@($(MAKE) -C $(CMAKE_BUILD_DIR) tags)
	@( $(MAKE) rtags)


rtags: compile_commands
	rc -J $(compile_commands)


.PHONY: distclean
distclean:  clean
	$(RM) -r $(CMAKE_BUILD_DIR)
	$(RM) -r Release
	$(RM) -r Debug
	$(RM) -r CodeblocksDebug
	$(RM) -r CodeblocksRelease
	$(RM) tags
	$(RM) cscope.out
	$(RM) cscope.out.*
	$(RM) *.orig
	$(RM) ncscope.out.*

