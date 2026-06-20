# Compiler and flags
NVCC = nvcc

TARGET = pointer_chasing_l3

SRCS = pointer_chasing_l3.cu vulkan_buffer.cpp

LIBS = -lvulkan -lcuda

all: $(TARGET)

$(TARGET): $(SRCS)
	$(NVCC) -arch=sm_80 -Xptxas -O0 -o $@ $^ $(LIBS)

clean:
	rm -f $(TARGET)
