file(GLOB SOURCES sts3x/*.c implementations/*.c embedded-common/*.c)

idf_component_register(
    SRCS ${SOURCES}
    INCLUDE_DIRS "sts-common" "embedded-common" "sts3x"
    PRIV_REQUIRES i2c_manager driver
)
