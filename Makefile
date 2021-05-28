# MAKE_COVERAGE := 1
 MAKE_TESTS := 1
# used build type : <Release | Debug | RelWithDebugInfor | MinSizeRel>
BUILD_TYPE = Debug
# BUILD_TYPE = Release
BUILD_ARCH = i386

# cmake path
CMAKE = cmake



#  build directory
CMAKE_BUILD_DIR= build
APP_FILE =$(CMAKE_BUILD_DIR)/app.mk
-include build/app.mk
# path to browser
BROWSER=sensible-browser
# generated compilerflags
compile_commands=$(CMAKE_BUILD_DIR)/compile_commands.json
# script to generate spell tags
SPELLGEN=./support/generateSpellingListFromCTags.py
# name of the generated spelltags file
SPELLFILE=$(APP_NAME)FromTags


# Switch to your prefered build tool.
BUILD_TOOL = "Unix Makefiles"
# BUILD_TOOL = "CodeBlocks - Unix Makefiles"
# BUILD_TOOL = "Eclipse CDT4 - Unix Makefiles"


CMAKE_FLAGS += \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DBUILD_SHARED_LIBS=ON

ifeq ($(BUILD_ARCH),i386)

CMAKE_FLAGS += \
	-DCMAKE_SYSTEM_PROCESSOR=__i386__ \
	-DCMAKE_C_FLAGS=-m32 \
	-DCMAKE_CXX_FLAGS=-m32 \
	-DCMAKE_EXE_LINKER_FLAGS=-m32 \
	-DCMAKE_MODULE_LINKER_FLAGS=-m32 \
	-DCMAKE_SHARED_LINKER_FLAGS=-m32 \
	-DBUILD_32=ON

endif

ifeq ($(BUILD_TYPE),Debug)


CMAKE_FLAGS += \
	-DENABLE_IWYU=OFF \
	-DENABLE_CPPLINT=OFF \
	-DENABLE_CLANGTIDY=OFF

ifdef MAKE_COVERAGE
MAKE_TESTS := 1
CMAKE_FLAGS += \
	-DENABLE_COVERAGE=ON
coverage: | run_utest
	@($(MAKE) -C $(CMAKE_BUILD_DIR) coverage && ${BROWSER} ${CMAKE_BUILD_DIR}/coverage/index.html)




else
CMAKE_FLAGS += \
	-DENABLE_COVERAGE=OFF
endif

# where is the doxygen generated index.html
HTML_INDEX_FILE=${CMAKE_BUILD_DIR}/doc/html/index.html

# name of executable the unittests executable
# APP_TEST=unittests_$(APP_NAME)

# TEST_APP_NAME=rfidTestApp
CMAKE_TEST_APP_DIR= $(CMAKE_BUILD_DIR)







CMAKE_FLAGS += \
	-DENABLE_COVERAGE=OFF \
	-DENABLE_IWYU=OFF \
	-DENABLE_CPPLINT=OFF \
	-DENABLE_CLANGTIDY=OFF

endif



default: package



$(CMAKE_BUILD_DIR): generate_build_tool


generate_build_tool:
	$(CMAKE) -H. -B$(CMAKE_BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -G $(BUILD_TOOL) \
	$(CMAKE_FLAGS)


$(APP_NAME): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) all


package: | package_deb package_src

package_src:  | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) package_source

package_deb: | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) package


install:
	sudo dpkg -i $(CMAKE_BUILD_DIR)/$(PACKAGE_NAME)*.deb

$(compile_commands) : $(APP_NAME)

rtags: $(compile_commands)
	rc -J $(compile_commands)

cppcheck: | $(compile_comands)
	cppcheck --project=$(CMAKE_BUILD_DIR)/compile_commands.json --enable=all


format: $(compile_commands)
	$(MAKE) -C $(CMAKE_BUILD_DIR) clangformat

.PHONY: $(APP_FILE)
ifdef ($APP_NAME)
$(APP_FILE): | $(APP_NAME)
else
$(APP_FILE): | generate_build_tool
endif


.PHONY: clean_spell
clean_spell:
	python2 $(SPELLGEN) -o ~/.vim/spell --clear $(SPELLFILE)

.PHONY: clean
clean: clean_spell
	$(RM) -fr tags
	$(RM) -fr cscope.out
	test -d $(CMAKE_BUILD_DIR) && $(MAKE) -sC $(CMAKE_BUILD_DIR) clean $(ARGS); cd ..

.PHONY: distclean
distclean:  clean
	$(RM) -fr $(RELEASE_DIR)
	$(RM) -fr $(CMAKE_BUILD_DIR)
	$(RM) -fr Release
	$(RM) -fr Debug
	$(RM) -fr CodeblocksDebug
	$(RM) -fr CodeblocksRelease
	$(RM) -f tags
	$(RM) -f cscope.out
	$(RM) -f cscope.out.*
	$(RM) -f *.orig
	$(RM) -f ncscope.out.*


