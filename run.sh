#!/bin/bash

# 定义颜色代码
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_BOLD_GREEN="\e[1;32m"
COLOR_RESET="\e[0m"

# 记录编译开始时间
start_time=$(date +%s)

# 创建并进入 build 目录，每次都会删除之前的文件
mkdir -p build
cd build
rm -rf _*

# 运行 CMake 和 Ninja 构建
echo -e "${COLOR_BLUE}正在生成构建系统...${COLOR_RESET}"
cmake -G Ninja .. && \
echo -e "${COLOR_BLUE}开始编译项目...${COLOR_RESET}" && \
cmake --build . --target all --config Release -- -j 16

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}构建失败！${COLOR_RESET}"
    exit 1
fi

# 获取当前工程所在的盘符
drive_letter=$(pwd | cut -d'/' -f2 | tr '[:lower:]' '[:upper:]')

# 修改 compile_commands.json 文件中的路径
sed -i "s|/c/|C:/|g; s|/d/|D:/|g; s|/e/|E:/|g; s|/f/|F:/|g; s|/g/|G:/|g; s|/h/|H:/|g; s|/i/|I:/|g; s|/j/|J:/|g; s|/k/|K:/|g; s|/l/|L:/|g; s|/m/|M:/|g; s|/n/|N:/|g; s|/o/|O:/|g; s|/p/|P:/|g; s|/q/|Q:/|g; s|/r/|R:/|g; s|/s/|S:/|g; s|/t/|T:/|g; s|/u/|U:/|g; s|/v/|V:/|g; s|/w/|W:/|g; s|/x/|X:/|g; s|/y/|Y:/|g; s|/z/|Z:/|g" compile_commands.json

# 获取 .ioc 文件的前缀
ioc_file=$(basename ../*.ioc .ioc)
elf_file="$ioc_file.elf"
bin_file="$ioc_file.bin"
hex_file="$ioc_file.hex"

# 检查 ELF 文件是否存在
if [ ! -f "$elf_file" ]; then
    echo -e "${COLOR_RED}错误：未找到 ELF 文件 $elf_file！${COLOR_RESET}"
    exit 1
fi

# 生成二进制文件和 HEX 文件
echo -e "${COLOR_BLUE}生成二进制文件...${COLOR_RESET}"
arm-none-eabi-objcopy -O binary "$elf_file" "$bin_file"
echo -e "${COLOR_BLUE}生成 HEX 文件...${COLOR_RESET}"
arm-none-eabi-objcopy -O ihex "$elf_file" "$hex_file"

# 检查二进制文件是否生成成功
if [ ! -f "$bin_file" ]; then
    echo -e "${COLOR_RED}错误：未生成二进制文件 $bin_file！${COLOR_RESET}"
    exit 1
fi

# 检查 HEX 文件是否生成成功
if [ ! -f "$hex_file" ]; then
    echo -e "${COLOR_RED}错误：未生成 HEX 文件 $hex_file！${COLOR_RESET}"
    exit 1
fi

# 打印内存使用情况（带彩色进度条）
print_memory_bar() {
    local used=$1
    local total=$2
    local label=$3
    
    # 转换为字节（输入单位KB）
    total_bytes=$((total * 1024))
    
    # 计算使用百分比
    if [ $total_bytes -eq 0 ]; then
        echo "错误：总大小不能为零！"
        return
    fi
    
    percent=$((used * 100 / total_bytes))
    ((percent > 100)) && percent=100

    # 根据百分比选择颜色
    if [ $percent -ge 90 ]; then
        color=$COLOR_RED
    elif [ $percent -ge 80 ]; then
        color=$COLOR_YELLOW
    else
        color=$COLOR_GREEN
    fi

    # 构建进度条
    bar_length=30
    filled=$((percent * bar_length / 100))
    empty=$((bar_length - filled))
    bar=$(printf "%${filled}s" | tr ' ' '█')
    space=$(printf "%${empty}s")

    # 转换使用量为KB并格式化输出
    used_kb=$(awk "BEGIN {printf \"%.2f\", $used/1024}")
    echo -e "${label}: ${color}${bar}${space}${COLOR_RESET} ${used_kb}KB/${total}KB (${percent}%)"
}

# 获取内存使用数据
echo -e "\n${COLOR_BOLD_GREEN}内存使用分析：${COLOR_RESET}"
size_info=$(arm-none-eabi-size "$elf_file" | tail -n1)
text=$(awk '{print $1}' <<< $size_info)
data=$(awk '{print $2}' <<< $size_info)
bss=$(awk '{print $3}' <<< $size_info)

# 计算各区域使用量（字节）
rom_used=$((text + data))      # Flash使用量 = text + data
ram_used=$((data + bss))       # RAM使用量 = data + bss
ccmram_used=$(arm-none-eabi-objdump -h $elf_file | awk '/.ccmram/ {print "0x"$3}' | xargs printf '%d') 

# 设置芯片内存参数（根据实际芯片修改以下数值）
FLASH_SIZE=128   # KB
RAM_SIZE=12     # KB
CCMRAM_SIZE=64    # KB

# 显示内存使用情况
print_memory_bar $rom_used $FLASH_SIZE "FLASH"
print_memory_bar $ram_used $RAM_SIZE "RAM"
[ $CCMRAM_SIZE -gt 0 ] && print_memory_bar $ccmram_used $CCMRAM_SIZE "CCMRAM"

# 计算编译耗时
end_time=$(date +%s)
duration=$((end_time - start_time))


# 打印编译成功信息
echo -e "\n${COLOR_RED}编译成功！！！${COLOR_RESET}"
echo -e "${COLOR_GREEN}编译耗时: ${COLOR_GREEN}${duration}秒${COLOR_RESET}"